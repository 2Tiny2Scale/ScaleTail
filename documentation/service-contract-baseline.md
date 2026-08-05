# Service contract baseline

This snapshot records the initial audit used to introduce the service contract
validator. The validator is intentionally stricter for new or modified
services; legacy findings remain visible in baseline mode until they are fixed.

## Current inventory

- 120 service directories contain a README, `.env`, and Compose entrypoint.
- 114 services use `compose.yaml`; 6 retain legacy `compose.yml` names.
- Three services use the `tailscale-node` profile because they advertise Tailscale routing roles instead of hosting an application.
- Multi-container services are listed explicitly in `tools/service-profiles.yml` with their ingress service and rationale.

## Remediation backlog

- `services/dockge`: `docker compose config --quiet` rejects the empty `STACKS_DIR` bind mount.
- `services/netbox`: `env_file: /.env` is an invalid absolute path from the service directory, and the ingress service lacks the Tailscale health dependency.
- `services/affine`, `services/flaresolverr`, `services/mattermost`, `services/next-explorer`, and `services/seafile`: ingress dependency chains need runtime-aware review and repair.
- `services/recyclarr`, `services/beszel-agent`, and `services/configarr`: the Tailscale sidecar does not persist its `/config` mount and needs an explicit decision or repair.
- `affine`, `filebrowser`, `minecraft`, and `next-explorer` are missing from the root README service index.
- Existing `.env` files contain secret-like defaults and mutable image tags; these are warnings in the baseline and must not be copied into new services.

Run the audit with:

```console
python tools/validate_services.py --all --baseline --format json
```

The initial audit reports eight structural/configuration errors (the two
Compose failures above plus six ingress health-dependency findings). The
remaining findings are tracked as warnings during rollout so the required PR
check can enforce changed services without hiding the repository-wide cleanup
work.

Runtime issues such as database DNS failures and Tailscale healthcheck regressions
require service-specific research and should be handled through the maintainer
workflow rather than by mechanical template rewrites.
