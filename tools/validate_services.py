#!/usr/bin/env python3
"""Validate ScaleTail service directories against the sidecar contract.

The validator intentionally checks deterministic repository invariants only. It
does not pull images or start containers; upstream service behavior is reviewed
by the ScaleTail maintainer skill.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable

try:
    import yaml
except ImportError:  # pragma: no cover - exercised by CI setup failures
    print("PyYAML is required; install tools/requirements.txt", file=sys.stderr)
    raise SystemExit(2)


@dataclass
class Finding:
    severity: str
    code: str
    path: str
    line: int | None
    message: str
    remediation: str
    service: str


class DuplicateKeyError(yaml.YAMLError):
    def __init__(self, key: Any, line: int):
        super().__init__(f"duplicate YAML key {key!r} at line {line}")
        self.key = key
        self.line = line


class UniqueKeyLoader(yaml.SafeLoader):
    """SafeLoader variant that rejects duplicate mapping keys."""


def _construct_unique_mapping(loader: UniqueKeyLoader, node: yaml.MappingNode, deep: bool = False):
    mapping: dict[Any, Any] = {}
    explicit_keys: set[Any] = set()
    for key_node, value_node in node.value:
        # YAML merge keys intentionally provide defaults that an explicit key
        # in the current mapping may override (for example netbox-worker).
        # They are not duplicate keys in the source mapping and must therefore
        # be handled separately from repeated explicit keys.
        if key_node.tag == "tag:yaml.org,2002:merge":
            merged = loader.construct_object(value_node, deep=deep)
            merged_items = merged.items() if isinstance(merged, dict) else []
            for merged_key, merged_value in merged_items:
                if merged_key not in mapping:
                    mapping[merged_key] = merged_value
            continue
        key = loader.construct_object(key_node, deep=deep)
        if key in explicit_keys:
            raise DuplicateKeyError(key, key_node.start_mark.line + 1)
        explicit_keys.add(key)
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping


UniqueKeyLoader.add_constructor(
    yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, _construct_unique_mapping
)


ROOT = Path(__file__).resolve().parents[1]
PROFILE_FILE = ROOT / "tools" / "service-profiles.yml"
ENV_COMMENT_ANCHORS = (
    "# Service Configuration",
    "# Network Configuration",
    "# Tailscale Configuration",
    "# Time Zone setting for containers",
    "# Any Container environment variables are declared below",
)
COMPOSE_COMMENT_ANCHORS = (
    "# Tailscale Sidecar Configuration",
    "# Image to be used",
    "# Name for local container management",
    "# Name used within your Tailscale environment",
    "# Tailscale Serve configuration",
    "# Tailscale requirement",
    "# Network configuration for Tailscale to work",
    "# Check Tailscale has a Tailnet IP and is operational",
    "# ${SERVICE}",
    "# Sidecar configuration to route",
)
PLACEHOLDER_PATTERNS = (
    "LINK TO PAGE",
    "information about the service",
    "Explain what the app does",
    "SERVICE with Tailscale Sidecar",
)
SECRET_KEY_RE = re.compile(
    r"(PASSWORD|SECRET|TOKEN|PRIVATE_KEY|API_KEY|ENCRYPTION_KEY|AUTHKEY|AUTH_KEY|TS_KEY)",
    re.I,
)
ENV_KEY_RE = re.compile(r"^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)$")
MAX_FILE_BYTES = 2_000_000
KNOWN_PROFILES = frozenset({"sidecar-web", "multi-container", "tailscale-node"})
APPROVED_TAILSCALE_NODE_SERVICES = frozenset({
    "tailscale-app-connector-node",
    "tailscale-exit-node",
    "tailscale-subnet-router-node",
})


def read_text_bounded(path: Path) -> str:
    if path.is_symlink() or not path.is_file():
        raise OSError(f"{path} must be a regular file, not a symlink or directory")
    if path.stat().st_size > MAX_FILE_BYTES:
        raise OSError(f"{path} exceeds the {MAX_FILE_BYTES}-byte validation limit")
    return path.read_text(encoding="utf-8")


def load_yaml(path: Path) -> Any:
    return yaml.load(read_text_bounded(path), Loader=UniqueKeyLoader)


def rel(path: Path, root: Path = ROOT) -> str:
    try:
        return str(path.resolve().relative_to(root.resolve()))
    except ValueError:
        return str(path)


def line_for(text: str, needle: str) -> int | None:
    for number, line in enumerate(text.splitlines(), 1):
        if needle in line:
            return number
    return None


def clean_env_value(value: str) -> str:
    value = value.strip()
    if " #" in value:
        value = value.split(" #", 1)[0].rstrip()
    if value.startswith("#"):
        return ""
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
        value = value[1:-1]
    return value


def parse_env(path: Path) -> tuple[dict[str, str], dict[str, int]]:
    values: dict[str, str] = {}
    lines: dict[str, int] = {}
    for number, raw in enumerate(read_text_bounded(path).splitlines(), 1):
        match = ENV_KEY_RE.match(raw.strip())
        if not match:
            continue
        key, value = match.groups()
        values[key] = clean_env_value(value)
        lines[key] = number
    return values, lines


def is_placeholder(value: str) -> bool:
    lowered = value.strip().lower()
    return (
        not lowered
        or lowered.startswith("${")
        or lowered.startswith("<")
        or lowered.startswith("// your")
        or lowered.startswith("your ")
        or lowered.startswith("replace")
        or lowered.startswith("change")
        or lowered.startswith("strongpassword")
        or lowered.startswith("some_random")
        or lowered in {"password", "changeme", "****", "..."}
        or "auth key from" in lowered
        or "generate a random" in lowered
    )


def env_items(environment: Any) -> dict[str, str]:
    if isinstance(environment, dict):
        return {str(key): "" if value is None else str(value) for key, value in environment.items()}
    result: dict[str, str] = {}
    if isinstance(environment, list):
        for item in environment:
            if not isinstance(item, str) or "=" not in item:
                continue
            key, value = item.split("=", 1)
            result[key] = value
    return result


def contains_mount(value: Any, target: str) -> bool:
    if isinstance(value, str):
        parts = value.split(":")
        return len(parts) >= 2 and parts[1] == target
    if isinstance(value, dict):
        return value.get("target") == target
    return False


def contains_device(value: Any, target: str) -> bool:
    if isinstance(value, str):
        parts = value.split(":")
        return value == target or (len(parts) >= 2 and parts[1] == target)
    if isinstance(value, dict):
        return value.get("target") == target or value.get("path_in_container") == target
    return False


def has_capability(value: Any, capability: str) -> bool:
    if not isinstance(value, list):
        return False
    return any(str(item).lower() == capability.lower() for item in value)


class Validator:
    def __init__(self, root: Path, profiles: dict[str, Any], baseline: bool = False):
        self.root = root
        self.profiles = profiles
        self.baseline = baseline
        self.findings: list[Finding] = []
        try:
            self.root_readme = read_text_bounded(root / "README.md")
        except OSError:
            self.root_readme = ""

    def add(
        self,
        service: str,
        severity: str,
        code: str,
        path: Path,
        message: str,
        remediation: str,
        line: int | None = None,
    ) -> None:
        self.findings.append(
            Finding(severity, code, rel(path, self.root), line, message, remediation, service)
        )

    def deterministic_severity(self) -> str:
        """Return the enforcement level for deterministic contract findings."""
        return "warning" if self.baseline else "error"

    def check_comment_order(
        self,
        service: str,
        path: Path,
        text: str,
        anchors: tuple[str, ...],
        code: str,
    ) -> None:
        positions = [(text.find(anchor), anchor) for anchor in anchors if anchor in text]
        if any(left[0] > right[0] for left, right in zip(positions, positions[1:])):
            self.add(
                service,
                self.deterministic_severity(),
                code,
                path,
                "Template comment anchors are out of order.",
                "Restore the template section order and keep service-specific comments beside the relevant setting.",
            )

    def validate_repository(self) -> None:
        profile_file = self.root / "tools" / "service-profiles.yml"
        profile_defs = self.profiles.get("profiles") if isinstance(self.profiles, dict) else None
        services = self.profiles.get("services") if isinstance(self.profiles, dict) else None
        if not isinstance(profile_defs, dict):
            self.add("repository", self.deterministic_severity(), "PROFILE_DEFINITIONS_INVALID", profile_file,
                     "Profile definitions must be a mapping.",
                     "Define sidecar-web, multi-container, and tailscale-node as profile mappings.")
            profile_defs = {}
        for profile in KNOWN_PROFILES:
            if profile not in profile_defs:
                self.add("repository", self.deterministic_severity(), "PROFILE_DEFINITION_MISSING", profile_file,
                         f"Required profile {profile!r} is missing.",
                         "Restore the maintainer-owned profile definition.")
        for profile in profile_defs:
            if profile not in KNOWN_PROFILES:
                self.add("repository", self.deterministic_severity(), "PROFILE_DEFINITION_UNKNOWN", profile_file,
                         f"Profile definition {profile!r} is not approved.",
                         "Remove the profile or add its behavior to the validator and maintainer documentation.")
        if not isinstance(services, dict):
            self.add("repository", self.deterministic_severity(), "PROFILE_SERVICES_INVALID", profile_file,
                     "Profile services must be a mapping.",
                     "Define service profile entries under services:.")
            services = {}
        service_dirs = {path.name for path in discover_all(self.root)}
        for service, entry in services.items():
            if not isinstance(service, str) or not isinstance(entry, dict):
                self.add("repository", self.deterministic_severity(), "PROFILE_ENTRY_INVALID", profile_file,
                         f"Profile entry {service!r} must be a mapping.",
                         "Use services.<name>.profile, reason, and ingress fields.")
                continue
            if service not in service_dirs:
                self.add(service, self.deterministic_severity(), "PROFILE_SERVICE_UNKNOWN", profile_file,
                         f"Profile entry refers to unknown service {service!r}.",
                         "Remove the stale entry or add the corresponding service directory.")
            profile = entry.get("profile", "sidecar-web")
            if not isinstance(profile, str) or profile not in KNOWN_PROFILES:
                self.add(service, self.deterministic_severity(), "PROFILE_UNKNOWN", profile_file,
                         f"Profile {profile!r} is not one of the approved profiles.",
                         "Use sidecar-web, multi-container, or tailscale-node.")
                continue
            if profile != "sidecar-web" and (
                not isinstance(entry.get("reason"), str) or not entry["reason"].strip()
            ):
                self.add(service, self.deterministic_severity(), "PROFILE_REASON_MISSING", profile_file,
                         f"Profile {profile!r} does not document its topology exception.",
                         "Add a concise maintainer-owned reason.")
            if profile == "multi-container" and (
                not isinstance(entry.get("ingress"), str) or not entry["ingress"].strip()
            ):
                self.add(service, self.deterministic_severity(), "PROFILE_INGRESS_MISSING", profile_file,
                         "Multi-container profiles must identify a string ingress service.",
                         "Set services.<name>.ingress to the routed application service.")
            if profile == "tailscale-node" and service not in APPROVED_TAILSCALE_NODE_SERVICES:
                self.add(service, "error", "PROFILE_NODE_NOT_APPROVED", profile_file,
                         "Only the approved Tailscale routing services may use tailscale-node.",
                         "Add maintainer-reviewed node behavior to the validator before using this profile.")
            if profile == "multi-container" and service in service_dirs:
                compose = self._compose_path(service)
                try:
                    compose_data = load_yaml(compose)
                    compose_services = compose_data.get("services", {}) if isinstance(compose_data, dict) else {}
                    ingress = entry.get("ingress")
                    if isinstance(compose_services, dict) and isinstance(ingress, str) and ingress not in compose_services:
                        self.add(service, self.deterministic_severity(), "PROFILE_INGRESS_UNKNOWN", profile_file,
                                 f"Ingress service {ingress!r} is not defined in the Compose file.",
                                 "Set ingress to an existing application service.")
                except (OSError, yaml.YAMLError):
                    pass
        if not self.root_readme:
            self.add("repository", self.deterministic_severity(), "README_ROOT_MISSING", self.root / "README.md",
                     "The root README is missing or is not a readable regular file.",
                     "Restore README.md as a regular UTF-8 file.")
        else:
            for service_dir in discover_all(self.root):
                self.validate_root_index(service_dir.name)

    def _compose_path(self, service: str) -> Path:
        directory = self.root / "services" / service
        compose = directory / "compose.yaml"
        return compose if compose.exists() else directory / "compose.yml"

    def validate_root_index(self, service: str) -> None:
        root_link = f"(services/{service})"
        root_lines = [
            (number, line) for number, line in enumerate(self.root_readme.splitlines(), 1)
            if root_link in line
        ]
        if not root_lines:
            self.add(service, self.deterministic_severity(), "README_INDEX_MISSING",
                     self.root / "README.md", "The service is not linked from the root README.",
                     "Add a categorized service row to README.md.")
        elif not any(
            "|" in line
            and len([part.strip() for part in line.split("|") if root_link not in part and part.strip()]) >= 2
            for _, line in root_lines
        ):
            self.add(service, self.deterministic_severity(), "README_INDEX_DESCRIPTION_MISSING",
                     self.root / "README.md", "The root README link does not include a service description.",
                     "Add the service to a categorized table with a concise description.", root_lines[0][0])

    def validate(self, service_dir: Path, is_new: bool = False) -> None:
        service = service_dir.name
        if service_dir.is_symlink() or not service_dir.is_dir() or service_dir.parent.name != "services":
            self.add(service, "error", "SERVICE_DIRECTORY_UNSAFE", service_dir,
                     "Service directories must be real directories directly under services/.",
                     "Replace symlinked or relocated service directories with a regular checkout directory.")
            return
        readme = service_dir / "README.md"
        env_file = service_dir / ".env"
        compose = service_dir / "compose.yaml"
        legacy_compose = service_dir / "compose.yml"
        service_profiles = self.profiles.get("services") if isinstance(self.profiles, dict) else {}
        if not isinstance(service_profiles, dict):
            service_profiles = {}
        raw_profile_entry = service_profiles.get(service, {})
        profile_entry = raw_profile_entry if isinstance(raw_profile_entry, dict) else {}
        profile = profile_entry.get("profile", "sidecar-web")
        profile_defs = self.profiles.get("profiles") if isinstance(self.profiles, dict) else {}
        if not isinstance(profile_defs, dict):
            profile_defs = {}

        if not isinstance(profile, str) or profile not in KNOWN_PROFILES or profile not in profile_defs:
            self.add(service, "error", "PROFILE_UNKNOWN", PROFILE_FILE,
                     f"Profile {profile!r} is not defined.",
                     "Use sidecar-web or add a reviewed profile definition.")
            profile = "sidecar-web"
        if profile != "sidecar-web" and not profile_entry.get("reason"):
            self.add(service, self.deterministic_severity(), "PROFILE_REASON_MISSING", PROFILE_FILE,
                     f"Profile {profile!r} does not document why this service differs from the default topology.",
                     "Add a concise maintainer-owned reason to tools/service-profiles.yml.")
        if profile == "multi-container" and (
            not isinstance(profile_entry.get("ingress"), str) or not profile_entry["ingress"].strip()
        ):
            self.add(service, self.deterministic_severity(), "PROFILE_INGRESS_MISSING", PROFILE_FILE,
                     "The multi-container profile must identify its ingress service.",
                     "Set services.<name>.ingress to the application routed through Tailscale.")
        if profile == "tailscale-node" and service not in APPROVED_TAILSCALE_NODE_SERVICES:
            self.add(service, "error", "PROFILE_NODE_NOT_APPROVED", PROFILE_FILE,
                     "Only the approved Tailscale routing services may use tailscale-node.",
                     "Add maintainer-reviewed node behavior to the validator before using this profile.")

        if not readme.exists():
            self.add(service, "error", "FILE_README_MISSING", readme,
                     "README.md is required.", "Copy the template README and document service-specific behavior.")
        if not env_file.exists():
            self.add(service, "error", "FILE_ENV_MISSING", env_file,
                     ".env is required.", "Copy the template .env and add non-secret service variables.")
        for candidate in (readme, env_file, compose, legacy_compose):
            if candidate.exists() and (candidate.is_symlink() or not candidate.is_file()):
                self.add(service, "error", "FILE_UNSAFE", candidate,
                         "Service contract files must be regular files, not symlinks or directories.",
                         "Replace the path with a regular file inside the checkout.")
        if not compose.exists():
            if legacy_compose.exists():
                severity = "warning" if not is_new else "error"
                self.add(service, severity, "COMPOSE_LEGACY_NAME", legacy_compose,
                         "New services must use compose.yaml; compose.yml is a legacy compatibility exception.",
                         "Rename the new service Compose file to compose.yaml.")
                compose = legacy_compose
            else:
                self.add(service, "error", "FILE_COMPOSE_MISSING", compose,
                         "compose.yaml is required.", "Copy the template Compose file.")
                return
        elif is_new and legacy_compose.exists():
            self.add(service, "error", "COMPOSE_BOTH_NAMES", legacy_compose,
                     "A service must not ship both compose.yaml and compose.yml.",
                     "Keep compose.yaml as the sole Compose entrypoint.")

        if env_file.exists() and env_file.is_file() and not env_file.is_symlink():
            self.validate_env(service, env_file, is_new, profile)
        try:
            readme_text = read_text_bounded(readme) if readme.exists() else ""
        except OSError as exc:
            readme_text = ""
            self.add(service, "error", "README_READ_FAILED", readme, str(exc),
                     "Make README.md a readable regular UTF-8 file within the size limit.")
        if readme.exists() and readme.is_file() and not readme.is_symlink():
            self.validate_readme(service, readme, readme_text, profile, is_new)
        self.validate_root_index(service)

        try:
            data = load_yaml(compose)
        except DuplicateKeyError as exc:
            self.add(service, "error", "YAML_DUPLICATE_KEY", compose,
                     str(exc), "Remove duplicate YAML keys; merge the mappings explicitly.", exc.line)
            return
        except yaml.YAMLError as exc:
            line = getattr(getattr(exc, "problem_mark", None), "line", None)
            self.add(service, "error", "YAML_INVALID", compose,
                     f"Compose YAML cannot be parsed: {exc}", "Fix YAML syntax and rerun validation.",
                     line + 1 if isinstance(line, int) else None)
            return
        except OSError as exc:
            self.add(service, "error", "COMPOSE_READ_FAILED", compose,
                     str(exc), "Make the Compose file readable.")
            return

        self.validate_compose(service, compose, data, profile, profile_entry, readme_text, is_new)
        self.validate_compose_config(service, compose)

    def validate_env(self, service: str, path: Path, is_new: bool, profile: str) -> None:
        try:
            text = read_text_bounded(path)
            values, lines = parse_env(path)
        except OSError as exc:
            self.add(service, "error", "ENV_READ_FAILED", path, str(exc),
                     "Make .env a readable regular UTF-8 file within the size limit.")
            return
        for anchor in ENV_COMMENT_ANCHORS:
            alternatives = (anchor, "#Time Zone setting for containers") if anchor.startswith("# Time Zone") else (anchor,)
            if not any(candidate in text for candidate in alternatives):
                self.add(service, self.deterministic_severity(), "ENV_COMMENT_MISSING", path,
                         f"Template comment section {anchor!r} is missing.",
                         "Restore the template comment section without removing service-specific comments.")
        self.check_comment_order(service, path, text, ENV_COMMENT_ANCHORS, "ENV_COMMENT_ORDER")
        required_keys = ("SERVICE", "DNS_SERVER", "TS_AUTHKEY", "TZ")
        if profile == "sidecar-web" and "IMAGE_URL" not in values:
            required_keys += ("IMAGE_URL",)
        if profile == "sidecar-web" and "SERVICEPORT" not in values:
            required_keys += ("SERVICEPORT",)
        for key in required_keys:
            if key not in values:
                self.add(service, self.deterministic_severity(), "ENV_KEY_MISSING", path,
                         f"Required variable {key} is missing.",
                         "Define the variable using the template .env structure.")
        empty_keys = ("SERVICE", "TZ")
        if profile == "sidecar-web":
            empty_keys += ("IMAGE_URL",)
        for key in empty_keys:
            if key in values and not values[key].strip():
                self.add(service, "error", "ENV_VALUE_EMPTY", path,
                         f"{key} must have a value.", "Set a safe non-secret value in .env.", lines.get(key))
        if "SERVICE" in values and re.search(r"\s", values["SERVICE"]):
            self.add(service, "error", "ENV_SERVICE_INVALID", path,
                     "SERVICE must not contain whitespace.", "Use a DNS/container-safe service name.", lines.get("SERVICE"))
        for key, value in values.items():
            if SECRET_KEY_RE.search(key) and value and not is_placeholder(value):
                self.add(service, self.deterministic_severity(), "ENV_SECRET_LIKE_VALUE", path,
                         f"{key} contains a non-placeholder secret-like value.",
                         "Use a blank or clearly documented placeholder; never commit real credentials.", lines.get(key))

    def validate_readme(self, service: str, path: Path, text: str, profile: str, is_new: bool) -> None:
        lower = text.lower()
        for placeholder in PLACEHOLDER_PATTERNS:
            if placeholder.lower() in lower:
                self.add(service, self.deterministic_severity(), "README_PLACEHOLDER", path,
                         f"Template placeholder text remains: {placeholder!r}.",
                         "Replace template placeholders with service-specific documentation.", line_for(text, placeholder))
        if not re.search(r"^# .*tailscale.*configuration", text, re.I | re.M):
            self.add(service, self.deterministic_severity(), "README_TITLE", path,
                     "README title should identify the service and Tailscale configuration.",
                     "Use the template title structure.", 1)
        required = {
            "overview": "Configuration Overview" in text,
            "upstream_link": bool(re.search(r"https?://", text)),
            "tailscale": "tailscale" in lower,
        }
        if profile != "tailscale-node":
            required.update({
                "ports": bool(re.search(r"\bport\b|listen|endpoint", lower)),
                "storage": bool(re.search(r"volume|storage|persistent|data", lower)),
                "prerequisites": bool(re.search(r"prerequisite|docker group|permission|uid|gid", lower)),
                "serve": bool(re.search(r"magicdns|serve|funnel|https", lower)),
                "links": bool(re.search(r"official|upstream|documentation|docs", lower)),
            })
        for name, present in required.items():
            if not present:
                self.add(service, self.deterministic_severity(), "README_CONTENT_MISSING", path,
                         f"README is missing required documentation area: {name}.",
                         "Document the template's service behavior, prerequisites, ports, storage, networking, and upstream links.")
        if profile == "tailscale-node" and "exit node" not in lower and "subnet" not in lower and "connector" not in lower:
            self.add(service, self.deterministic_severity(), "README_NODE_CONTEXT_MISSING", path,
                     "Tailscale-node README does not explain the advertised routing role.",
                     "Document the node role and required Tailscale approval steps.")

    def validate_compose(
        self,
        service: str,
        path: Path,
        data: Any,
        profile: str,
        profile_entry: dict[str, Any],
        readme_text: str,
        is_new: bool,
    ) -> None:
        if not isinstance(data, dict) or not isinstance(data.get("services"), dict):
            self.add(service, "error", "COMPOSE_SERVICES_MISSING", path,
                     "Compose file must define a services mapping.", "Use the template Compose structure.")
            return
        services = data["services"]
        app_services = [name for name in services if name != "tailscale"]
        if profile == "sidecar-web" and len(app_services) != 1:
            self.add(service, self.deterministic_severity(), "PROFILE_REQUIRED", path,
                     "This Compose file has more than one non-Tailscale service but uses the default sidecar-web profile.",
                     "Add a reviewed multi-container profile entry with the routed ingress service and topology reason.")
        for name, value in services.items():
            if not isinstance(value, dict) or name == "tailscale":
                continue
            image = str(value.get("image", ""))
            image_ref = image.rsplit("/", 1)[-1]
            if image.endswith(":latest") or (image and not image.startswith("${") and ":" not in image_ref and "@" not in image):
                self.add(service, "warning", "IMAGE_MUTABLE_TAG", path,
                         f"Service {name!r} uses a mutable or implicit-latest image reference {image!r}.",
                         "Prefer a reviewed immutable version when changing this service; mass pinning is a separate rollout.")
        tailscale = services.get("tailscale")
        if not isinstance(tailscale, dict):
            self.add(service, "error", "TAILSCALE_SERVICE_MISSING", path,
                     "A tailscale service is required for this profile.", "Add the template Tailscale sidecar.")
            return
        self.validate_tailscale(service, path, tailscale, data, profile, is_new)
        if profile == "tailscale-node":
            self.validate_tailscale_node(service, path, tailscale, profile)
            return

        ingress_name = profile_entry.get("ingress")
        if ingress_name is not None and not isinstance(ingress_name, str):
            self.add(service, self.deterministic_severity(), "PROFILE_INGRESS_INVALID", path,
                     "The configured ingress service name must be a string.",
                     "Set ingress to the name of an application service.")
            ingress_name = None
        if not ingress_name:
            if "application" in services:
                ingress_name = "application"
            else:
                candidates = [
                    name for name, value in services.items()
                    if isinstance(value, dict) and value.get("container_name") == "app-${SERVICE}"
                ]
                if candidates:
                    ingress_name = candidates[0]
                else:
                    candidates = [
                        name for name, value in services.items()
                        if isinstance(value, dict) and value.get("network_mode") == "service:tailscale"
                    ]
                    ingress_name = candidates[0] if candidates else None
        ingress = services.get(ingress_name) if ingress_name else None
        if not isinstance(ingress, dict):
            self.add(service, "error", "INGRESS_SERVICE_MISSING", path,
                     "The service profile does not identify a valid ingress service.",
                     "Add an explicit ingress service to tools/service-profiles.yml.")
            return
        if ingress.get("network_mode") != "service:tailscale":
            self.add(service, "error", "SIDECAR_NETWORK_MODE", path,
                     f"Ingress service {ingress_name!r} must use network_mode: service:tailscale.",
                     "Route the ingress service through the Tailscale sidecar.", line_for(read_text_bounded(path), "network_mode:"))
        depends = ingress.get("depends_on")
        tail_dep = depends.get("tailscale") if isinstance(depends, dict) else None
        if not isinstance(tail_dep, dict) or tail_dep.get("condition") != "service_healthy":
            self.add(service, "error", "TAILSCALE_HEALTH_DEPENDENCY", path,
                     f"Ingress service {ingress_name!r} must depend on a healthy tailscale service.",
                     "Add depends_on.tailscale.condition: service_healthy.")
        container_name = str(ingress.get("container_name", ""))
        if profile == "sidecar-web" and container_name != "app-${SERVICE}":
            self.add(service, "error", "APP_CONTAINER_NAME", path,
                     "The default ingress container must be named app-${SERVICE}.",
                     "Use the template container name or add a reviewed multi-container profile.")
        elif profile == "multi-container" and not (container_name.startswith("app-") or container_name == "${SERVICE}"):
            self.add(service, "error", "APP_CONTAINER_NAME", path,
                     f"Ingress container {container_name!r} is not an approved app container name.",
                     "Use an app-* name or document the intentional name in the profile.")
        if is_new and "healthcheck" not in ingress:
            self.add(service, "error", "APP_HEALTHCHECK_MISSING", path,
                     "New ingress services must define an application healthcheck.",
                     "Use an image-supported command or endpoint and document it in the README.")

        published_ports = {
            name: value.get("ports")
            for name, value in services.items()
            if isinstance(value, dict) and value.get("ports")
        }
        if published_ports:
            if not re.search(r"(?i)\b(lan|local network|host port|0\.0\.0\.0)\b", readme_text):
                self.add(service, self.deterministic_severity(), "PORTS_UNDOCUMENTED", path,
                         f"Published host ports on {', '.join(published_ports)} are not explained in the README.",
                         "Explain why host/LAN exposure is required and which ports are published.")

        compose_text = read_text_bounded(path)
        tail_environment = env_items(tailscale.get("environment"))
        for anchor in COMPOSE_COMMENT_ANCHORS:
            if anchor.startswith("# Tailscale Serve") and "TS_SERVE_CONFIG" not in tail_environment:
                continue
            if anchor not in compose_text:
                self.add(service, self.deterministic_severity(), "COMPOSE_COMMENT_MISSING", path,
                         f"Template comment anchor {anchor!r} is missing.",
                         "Restore the template comment adjacent to the relevant setting.")
        self.check_comment_order(service, path, compose_text, COMPOSE_COMMENT_ANCHORS, "COMPOSE_COMMENT_ORDER")
        if "TS_SERVE_CONFIG" in tail_environment:
            config = data.get("configs", {}).get("ts-serve") if isinstance(data.get("configs"), dict) else None
            content = config.get("content", "") if isinstance(config, dict) else ""
            config_mount = any(
                (isinstance(item, dict) and item.get("source") == "ts-serve" and item.get("target") == "/config/serve.json")
                or (isinstance(item, str) and len(item.split(":")) >= 2
                    and item.split(":")[0] == "ts-serve"
                    and item.split(":")[1] == "/config/serve.json")
                for item in tailscale.get("configs", [])
            )
            if not config_mount:
                self.add(service, self.deterministic_severity(), "SERVE_CONFIG_MOUNT_MISSING", path,
                         "TS_SERVE_CONFIG is enabled but ts-serve is not mounted at /config/serve.json.",
                         "Mount the ts-serve config source at the path named by TS_SERVE_CONFIG.")
            if not content or "Proxy" not in content:
                self.add(service, self.deterministic_severity(), "SERVE_PROXY_MISSING", path,
                         "TS_SERVE_CONFIG is enabled but the ts-serve config has no Proxy handler.",
                         "Add a documented proxy target or remove TS_SERVE_CONFIG when Serve is not used.")
            proxies = re.findall(r"[\"']Proxy[\"']\s*:\s*[\"']([^\"']+)", str(content))
            for proxy in proxies:
                if "${" in proxy:
                    self.add(service, self.deterministic_severity(), "SERVE_PROXY_INTERPOLATION", path,
                             f"Serve proxy target {proxy!r} still contains Compose interpolation.",
                             "Use the service's actual internal loopback port; Serve config does not consume .env values.")
                if re.search(r":80(?:/|$)", proxy) and self._env_service_port(service) not in {None, "", "80"}:
                    self.add(service, "warning", "SERVE_PROXY_DEFAULT_PORT", path,
                             f"Serve proxy target {proxy!r} still uses the template's port 80.",
                             "Verify the service's actual internal listening port against upstream documentation.")

    def validate_tailscale_node(self, service: str, path: Path, tailscale: dict[str, Any], profile: str) -> None:
        environment = env_items(tailscale.get("environment"))
        extra_args = environment.get("TS_EXTRA_ARGS", "")
        expected_args = {
            "tailscale-exit-node": "--advertise-exit-node",
            "tailscale-app-connector-node": "--advertise-connector",
        }
        expected_arg = expected_args.get(service)
        if expected_arg and expected_arg not in extra_args:
            self.add(service, self.deterministic_severity(), "NODE_ROLE_ARGUMENT_MISSING", path,
                     f"{service} must advertise its role with {expected_arg}.",
                     "Restore the role-specific TS_EXTRA_ARGS value.")
        if service == "tailscale-subnet-router-node" and not environment.get("TS_ROUTES", "").strip():
            self.add(service, self.deterministic_severity(), "NODE_ROUTES_MISSING", path,
                     "The subnet-router profile must define TS_ROUTES.",
                     "Set the approved subnet route list in .env and pass it to Tailscale.")
        if tailscale.get("network_mode") != "bridge":
            self.add(service, self.deterministic_severity(), "NODE_NETWORK_MODE", path,
                     "Tailscale routing nodes must use bridge network mode.",
                     "Use network_mode: bridge so forwarding and advertised routes work.")
        sysctls = tailscale.get("sysctls")
        if not isinstance(sysctls, dict) or sysctls.get("net.ipv4.ip_forward") not in {1, "1"} or sysctls.get("net.ipv6.conf.all.forwarding") not in {1, "1"}:
            self.add(service, self.deterministic_severity(), "NODE_FORWARDING_SYSCTLS", path,
                     "Tailscale routing nodes must enable IPv4 and IPv6 forwarding.",
                     "Set both forwarding sysctls in the node Compose service.")

    def _env_service_port(self, service: str) -> str | None:
        env = self.root / "services" / service / ".env"
        if not env.exists():
            return None
        try:
            values, _ = parse_env(env)
        except OSError:
            return None
        return values.get("SERVICEPORT")

    def validate_tailscale(
        self,
        service: str,
        path: Path,
        tailscale: dict[str, Any],
        data: dict[str, Any],
        profile: str,
        is_new: bool,
    ) -> None:
        text = read_text_bounded(path)
        image = str(tailscale.get("image", ""))
        image_without_digest = image.split("@", 1)[0]
        image_repo = image_without_digest.rsplit(":", 1)[0]
        if image_repo not in {"tailscale/tailscale", "docker.io/tailscale/tailscale"}:
            self.add(service, "error", "TAILSCALE_IMAGE", path,
                     "tailscale.image must use the tailscale/tailscale image.",
                     "Use tailscale/tailscale with a reviewed tag.")
        if image.endswith(":latest"):
            self.add(service, "warning", "IMAGE_MUTABLE_TAG", path,
                     "Tailscale uses the mutable latest tag.",
                     "Prefer a reviewed version when changing this service; pinning all existing services is a separate rollout.")
        if tailscale.get("container_name") != "tailscale-${SERVICE}":
            self.add(service, "error", "TAILSCALE_CONTAINER_NAME", path,
                     "Tailscale container must be named tailscale-${SERVICE}.", "Use the template container name.")
        if tailscale.get("hostname") != "${SERVICE}":
            self.add(service, "error", "TAILSCALE_HOSTNAME", path,
                     "Tailscale hostname must be ${SERVICE}.", "Use SERVICE as the Tailscale hostname.")
        environment = env_items(tailscale.get("environment"))
        for key in ("TS_AUTHKEY", "TS_STATE_DIR", "TS_USERSPACE", "TS_ENABLE_HEALTH_CHECK", "TS_LOCAL_ADDR_PORT"):
            if key not in environment:
                self.add(service, "error", "TAILSCALE_ENV_MISSING", path,
                         f"Tailscale environment variable {key} is missing.", "Restore the template Tailscale environment.")
        if environment.get("TS_ENABLE_HEALTH_CHECK", "").lower() != "true":
            self.add(service, "error", "TAILSCALE_HEALTH_DISABLED", path,
                     "TS_ENABLE_HEALTH_CHECK must be true.", "Enable the Tailscale health endpoint.")
        health = tailscale.get("healthcheck")
        health_text = json.dumps(health, sort_keys=True) if health is not None else ""
        if "/healthz" not in health_text:
            self.add(service, "error", "TAILSCALE_HEALTHCHECK", path,
                     "Tailscale healthcheck must probe /healthz.", "Use the template healthcheck endpoint.")
        volumes = tailscale.get("volumes", [])
        if profile != "tailscale-node" and not any(contains_mount(item, "/config") for item in volumes):
            self.add(service, self.deterministic_severity(), "TAILSCALE_CONFIG_VOLUME", path,
                     "Tailscale must mount a config directory at /config.", "Keep the template config mount.")
        if not any(contains_mount(item, "/var/lib/tailscale") for item in volumes):
            self.add(service, "error", "TAILSCALE_STATE_VOLUME", path,
                     "Tailscale must persist /var/lib/tailscale.", "Keep the template state mount.")
        if not any(contains_device(item, "/dev/net/tun") for item in tailscale.get("devices", [])):
            self.add(service, "error", "TAILSCALE_TUN_DEVICE", path,
                     "Tailscale must receive /dev/net/tun.", "Keep the template TUN device mapping.")
        if not has_capability(tailscale.get("cap_add"), "net_admin"):
            self.add(service, "error", "TAILSCALE_NET_ADMIN", path,
                     "Tailscale must have net_admin capability.", "Keep the template capability.")
        if not tailscale.get("restart"):
            self.add(service, "error", "TAILSCALE_RESTART", path,
                     "Tailscale must define a restart policy.", "Use restart: always or an explicitly documented equivalent.")
        if "# Tailscale Sidecar Configuration" not in text:
            self.add(service, self.deterministic_severity(), "COMPOSE_COMMENT_MISSING", path,
                     "The Tailscale sidecar comment is missing.", "Restore the template comment.")

    def validate_compose_config(self, service: str, compose: Path) -> None:
        try:
            result = subprocess.run(
                ["docker", "compose", "-f", compose.name, "config", "--quiet"],
                cwd=compose.parent,
                text=True,
                capture_output=True,
                timeout=90,
                check=False,
            )
        except FileNotFoundError:
            self.add(service, "warning", "COMPOSE_NOT_AVAILABLE", compose,
                     "Docker Compose is not installed; static checks completed without config validation.",
                     "Run docker compose config --quiet in CI or a Docker-enabled environment.")
            return
        except subprocess.TimeoutExpired:
            self.add(service, "error", "COMPOSE_CONFIG_TIMEOUT", compose,
                     "docker compose config --quiet timed out.", "Fix external env_file references and rerun the command.")
            return
        interpolation_warnings = [
            line.strip() for line in (result.stderr or "").splitlines()
            if "not set" in line.lower() or "undefined" in line.lower()
        ]
        if interpolation_warnings and result.returncode == 0:
            self.add(service, self.deterministic_severity(), "COMPOSE_INTERPOLATION_WARNING", compose,
                     interpolation_warnings[0],
                     "Define the referenced variable or document it as an explicitly optional value.")
        if result.returncode:
            detail = (result.stderr or result.stdout).strip().splitlines()
            message = detail[-1] if detail else "docker compose config --quiet failed"
            self.add(service, "error", "COMPOSE_CONFIG_INVALID", compose,
                     message, "Run docker compose config --quiet from the service directory and fix the reported issue.")


def changed_services(root: Path, reference: str) -> tuple[list[Path], set[str]]:
    try:
        result = subprocess.run(
            ["git", "diff", "--name-status", reference, "HEAD"],
            cwd=root,
            text=True,
            capture_output=True,
            check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return [], set()
    dirs: set[str] = set()
    new: set[str] = set()
    for raw in result.stdout.splitlines():
        parts = raw.split("\t")
        if len(parts) < 2:
            continue
        status, changed = parts[0], parts[-1]
        path = Path(changed)
        if len(path.parts) < 3 or path.parts[0] != "services":
            continue
        service = path.parts[1]
        dirs.add(service)
        if status.startswith(("A", "R")):
            new.add(service)
    return [root / "services" / name for name in sorted(dirs)], new


def discover_all(root: Path) -> list[Path]:
    services = root / "services"
    return sorted(path for path in services.iterdir() if path.is_dir()) if services.exists() else []


def emit(findings: Iterable[Finding], output_format: str) -> None:
    items = list(findings)
    if output_format == "json":
        print(json.dumps([asdict(item) for item in items], indent=2))
        return
    for item in items:
        location = item.path if item.line is None else f"{item.path}:{item.line}"
        message = f"[{item.code}] {item.message} Fix: {item.remediation}"
        if output_format == "github":
            command = "warning" if item.severity == "warning" else "error"
            print(f"::{command} file={item.path},line={item.line or 1}::{message}")
        else:
            print(f"{location} [{item.severity.upper()}] {message}")
    if not items:
        print("ScaleTail service validation passed.")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", help="service directories to validate")
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--all", action="store_true", help="validate every service directory")
    parser.add_argument("--baseline", action="store_true", help="audit mode: report findings without failing")
    parser.add_argument("--check-repository", action="store_true", help="validate profile metadata and root README coverage")
    parser.add_argument("--changed-from", metavar="REF", help="validate only service directories changed since REF")
    parser.add_argument("--new-service", action="append", default=[], help="mark a service path as newly added")
    parser.add_argument("--format", choices=("text", "github", "json"), default="text")
    args = parser.parse_args(argv)
    root = args.root.resolve()
    profile_error: str | None = None
    try:
        loaded_profiles = load_yaml(root / "tools" / "service-profiles.yml")
        profiles = loaded_profiles if isinstance(loaded_profiles, dict) else {}
        if not isinstance(loaded_profiles, dict):
            profile_error = "service-profiles.yml must contain a top-level mapping"
    except (OSError, yaml.YAMLError) as exc:
        profiles = {}
        profile_error = str(exc)
    validator = Validator(root, profiles, baseline=args.baseline)
    if profile_error:
        validator.add("repository", validator.deterministic_severity(), "PROFILE_FILE_INVALID",
                      root / "tools" / "service-profiles.yml", profile_error,
                      "Restore a readable YAML profile mapping.")
    if args.check_repository:
        validator.validate_repository()
    if args.changed_from:
        paths, new_services = changed_services(root, args.changed_from)
        if not paths:
            paths = [root / path for path in args.paths]
        new_services.update(Path(path).name for path in args.new_service)
    elif args.check_repository and not args.paths:
        paths = []
        new_services = set(args.new_service)
    elif args.all or not args.paths:
        paths = discover_all(root)
        new_services = {Path(path).name for path in args.new_service}
    else:
        paths = [Path(path).resolve() for path in args.paths]
        new_services = {Path(path).name for path in args.new_service}
    for path in paths:
        if path.is_dir() and path.parent.name == "services":
            validator.validate(path, is_new=path.name in new_services)
    emit(validator.findings, args.format)
    if args.baseline:
        return 0
    return 1 if any(item.severity == "error" for item in validator.findings) else 0


if __name__ == "__main__":
    raise SystemExit(main())
