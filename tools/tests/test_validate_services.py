import sys
import tempfile
import unittest
from pathlib import Path
from subprocess import CompletedProcess
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).parents[1]))
import validate_services  # noqa: E402


TEMPLATE_ENV = """# Service Configuration
SERVICE=demo
IMAGE_URL=example/demo:1.0
# Network Configuration
SERVICEPORT=8080
DNS_SERVER=9.9.9.9
# Tailscale Configuration
TS_AUTHKEY=
# Time Zone setting for containers
TZ=Europe/Amsterdam
# Any Container environment variables are declared below
"""

TEMPLATE_README = """# Demo with Tailscale Sidecar Configuration

## Configuration Overview

Demo uses Tailscale Serve over port 8080. Prerequisites include Docker access.
Persistent data is stored in the documented volume. See the official
documentation at https://example.com/docs.
"""

BASE_COMPOSE = """configs:
  ts-serve:
    content: |
      {\"TCP\":{\"443\":{\"HTTPS\":true}},\"Web\":{\"$${TS_CERT_DOMAIN}:443\":{\"Handlers\":{\"/\":{\"Proxy\":\"http://127.0.0.1:8080\"}}}}}
services:
  # Tailscale Sidecar Configuration
  tailscale:
    image: tailscale/tailscale:1.0 # Image to be used
    container_name: tailscale-${SERVICE} # Name for local container management
    hostname: ${SERVICE} # Name used within your Tailscale environment
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_SERVE_CONFIG=/config/serve.json # Tailscale Serve configuration
      - TS_USERSPACE=false
      - TS_ENABLE_HEALTH_CHECK=true
      - TS_LOCAL_ADDR_PORT=127.0.0.1:41234
    volumes:
      - ./config:/config # Config folder used to store Tailscale files
      - ./ts/state:/var/lib/tailscale # Tailscale requirement
    devices:
      - /dev/net/tun:/dev/net/tun # Network configuration for Tailscale to work
    cap_add:
      - net_admin # Tailscale requirement
    healthcheck:
      test: [\"CMD\", \"wget\", \"--spider\", \"-q\", \"http://127.0.0.1:41234/healthz\"] # Check Tailscale has a Tailnet IP and is operational
    restart: always
  # ${SERVICE}
  application:
    image: ${IMAGE_URL} # Image to be used
    network_mode: service:tailscale # Sidecar configuration to route ${SERVICE} through Tailscale
    container_name: app-${SERVICE} # Name for local container management
    environment: # Variables are declared in .env file.
      - TZ=${TZ}
    volumes:
      - ./${SERVICE}-data:/config
    depends_on:
      database:
        condition: service_started
    healthcheck:
      test: [\"CMD\", \"pgrep\", \"-f\", \"demo\"]
    restart: always
  database:
    image: postgres:16
"""


class ValidateServicesTests(unittest.TestCase):
    def test_duplicate_yaml_keys_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "compose.yaml"
            path.write_text("services:\n  app:\n    image: one\n    image: two\n", encoding="utf-8")
            with self.assertRaises(validate_services.DuplicateKeyError):
                validate_services.load_yaml(path)

    def test_malformed_yaml_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "compose.yaml"
            path.write_text("services:\n  app: [\n", encoding="utf-8")
            with self.assertRaises(validate_services.yaml.YAMLError):
                validate_services.load_yaml(path)

    def test_new_service_requires_tailscale_health_dependency(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            service = root / "services" / "demo"
            (root / "tools").mkdir(parents=True)
            service.mkdir(parents=True)
            (root / "README.md").write_text("[Demo](services/demo)\n", encoding="utf-8")
            (service / ".env").write_text(TEMPLATE_ENV, encoding="utf-8")
            (service / "README.md").write_text(TEMPLATE_README, encoding="utf-8")
            (service / "compose.yaml").write_text(BASE_COMPOSE, encoding="utf-8")
            validator = validate_services.Validator(
                root,
                {"profiles": {"sidecar-web": {}}, "services": {}},
            )
            with patch.object(
                validate_services.subprocess,
                "run",
                return_value=CompletedProcess([], 0, "", ""),
            ):
                validator.validate(service, is_new=True)
            codes = {finding.code for finding in validator.findings}
            self.assertIn("TAILSCALE_HEALTH_DEPENDENCY", codes)

    def test_tailscale_node_does_not_require_serve_config(self):
        validator = validate_services.Validator(
            validate_services.ROOT,
            validate_services.load_yaml(validate_services.PROFILE_FILE),
            baseline=True,
        )
        with patch.object(
            validate_services.subprocess,
            "run",
            return_value=CompletedProcess([], 0, "", ""),
        ):
            validator.validate(validate_services.ROOT / "services" / "tailscale-exit-node")
        codes = {finding.code for finding in validator.findings}
        self.assertNotIn("TAILSCALE_CONFIG_VOLUME", codes)
        self.assertNotIn("INGRESS_SERVICE_MISSING", codes)

    def test_extra_application_requires_explicit_profile(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            service = root / "services" / "demo"
            (root / "tools").mkdir(parents=True)
            service.mkdir(parents=True)
            (root / "README.md").write_text("| Demo | A service | (services/demo) |\n", encoding="utf-8")
            (service / ".env").write_text(TEMPLATE_ENV, encoding="utf-8")
            (service / "README.md").write_text(TEMPLATE_README, encoding="utf-8")
            (service / "compose.yaml").write_text(BASE_COMPOSE + "  worker:\n    image: example/worker:1.0\n", encoding="utf-8")
            validator = validate_services.Validator(
                root,
                {"profiles": {"sidecar-web": {}}, "services": {}},
            )
            with patch.object(
                validate_services.subprocess,
                "run",
                return_value=CompletedProcess([], 0, "", ""),
            ):
                validator.validate(service, is_new=True)
            self.assertIn("PROFILE_REQUIRED", {finding.code for finding in validator.findings})

    def test_published_ports_need_readme_explanation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            service = root / "services" / "demo"
            (root / "tools").mkdir(parents=True)
            service.mkdir(parents=True)
            (root / "README.md").write_text("[Demo](services/demo)\n", encoding="utf-8")
            (service / ".env").write_text(TEMPLATE_ENV, encoding="utf-8")
            (service / "README.md").write_text(TEMPLATE_README.replace("port 8080", "the app"), encoding="utf-8")
            (service / "compose.yaml").write_text(BASE_COMPOSE.replace("    healthcheck:\n", "    ports:\n      - 0.0.0.0:8080:8080\n    healthcheck:\n"), encoding="utf-8")
            validator = validate_services.Validator(
                root,
                {"profiles": {"sidecar-web": {}}, "services": {}},
            )
            with patch.object(
                validate_services.subprocess,
                "run",
                return_value=CompletedProcess([], 0, "", ""),
            ):
                validator.validate(service, is_new=True)
            self.assertIn("PORTS_UNDOCUMENTED", {finding.code for finding in validator.findings})

    def test_secret_like_values_are_reported(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / ".env"
            path.write_text(TEMPLATE_ENV + "DATABASE_PASSWORD=real-value\n", encoding="utf-8")
            validator = validate_services.Validator(validate_services.ROOT, {"services": {}})
            validator.validate_env("demo", path, is_new=True, profile="sidecar-web")
            self.assertIn("ENV_SECRET_LIKE_VALUE", {finding.code for finding in validator.findings})

    def test_missing_template_comments_are_reported(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / ".env"
            path.write_text("SERVICE=demo\nIMAGE_URL=example/demo:1.0\n", encoding="utf-8")
            validator = validate_services.Validator(validate_services.ROOT, {"services": {}})
            validator.validate_env("demo", path, is_new=True, profile="sidecar-web")
            self.assertIn("ENV_COMMENT_MISSING", {finding.code for finding in validator.findings})

    def test_invalid_serve_proxy_is_reported(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            service = root / "services" / "demo"
            (root / "tools").mkdir(parents=True)
            service.mkdir(parents=True)
            (root / "README.md").write_text("[Demo](services/demo)\n", encoding="utf-8")
            (service / ".env").write_text(TEMPLATE_ENV, encoding="utf-8")
            (service / "README.md").write_text(TEMPLATE_README, encoding="utf-8")
            (service / "compose.yaml").write_text(
                BASE_COMPOSE.replace("http://127.0.0.1:8080", "http://127.0.0.1:${SERVICEPORT}"),
                encoding="utf-8",
            )
            validator = validate_services.Validator(
                root,
                {"profiles": {"sidecar-web": {}}, "services": {}},
            )
            with patch.object(
                validate_services.subprocess,
                "run",
                return_value=CompletedProcess([], 0, "", ""),
            ):
                validator.validate(service, is_new=True)
            self.assertIn("SERVE_PROXY_INTERPOLATION", {finding.code for finding in validator.findings})


if __name__ == "__main__":
    unittest.main()
