# Contributing to ScaleTail

Thanks for helping expand these Tailscale sidecar examples. Keeping services aligned with the template makes it easier for users to migrate existing Compose stacks without breaking them.

## Adding a new service

1. Copy `templates/service-template` into `services/<service-name>` and rename the compose and README files accordingly.
2. Update `compose.yaml`:
   - Keep the Tailscale container named `tailscale-<service>` and the app container named `app-<service>`.
   - Set `IMAGE_URL`, `SERVICEPORT`, and any other app variables in `.env`; do not commit secrets or real auth keys.
   - Leave `network_mode: service:tailscale` in place and keep `depends_on` using the Tailscale health check.
   - Keep the `ports` section commented unless LAN exposure is required; explain why in the README if you expose anything.
   - Adjust volumes to match the service, and pre-create bind-mount paths so Docker does not create root-owned folders. (optional)
   - If the service needs devices (GPU, render, fuse, etc.) or extra capabilities, add them explicitly and mention them in the README. (optional)
3. Update `"Proxy":"http://127.0.0.1:80"` in `compose.yaml` with the app's actual internal port; it does not consume `.env` values automatically. Remove `TS_SERVE_CONFIG` if Serve/Funnel is not needed.
4. Fill in the service README using the template:
   - Briefly describe the app and why Tailscale helps.
   - List prerequisites (user in `docker` group, GPU/group membership, devices).
   - Call out gotchas: initial admin setup, default credentials, path expectations, required group IDs, or config directory names that must change.
   - Clarify MagicDNS/HTTPS steps (`TS_ACCEPT_DNS`), optional 0.0.0.0 port exposure, and any health checks.
   - Link to upstream service docs and any official setup videos.
5. Sanity-check the stack with `docker compose config` from the service directory to catch typos and missing variables.

### Service contract and validation

The files in `templates/service-template` are the canonical structure for a
new service. Keep the explanatory comments in the Tailscale and application
blocks; add service-specific comments beside the template comments instead of
deleting them. New services must use `compose.yaml`, include a complete `.env`
template, and add a categorized link to the root `README.md`.

Run the repository validator before opening a pull request:

```console
python -m pip install -r tools/requirements.txt
python tools/validate_services.py services/<service-name>
docker compose config --quiet
```

The `service-contract` GitHub check runs these deterministic checks for changed
services. It does not pull images or start third-party containers. Multi-container
and Tailscale-node layouts must be listed in `tools/service-profiles.yml` with
an ingress service and a reason for the exception.

The validator cannot prove that an upstream image's internal port, healthcheck,
volume path, UID/GID, or device requirements are correct. Verify those details
against the service's official documentation and record the links and gotchas in
the service README before requesting review.

## Updating an existing service

- Keep the sidecar pattern intact (`network_mode: service:tailscale`, health checks, `depends_on`).
- Avoid removing existing volumes or changing container names unless the change is clearly documented in the README.
- Preserve the template comments and run the validator for the service after any
  Compose or `.env` change.

## Issue and pull request review

Use the personal `scaletail-maintainer` Codex skill for research-heavy reviews,
new-service validation, and issue triage. It reports findings by default and
only edits the local checkout when explicitly asked to fix something. It does
not push branches, post GitHub comments, resolve review threads, apply labels,
or close issues unless those actions are separately requested.

Issue triage uses the existing GitHub labels plus these small cross-cutting
labels when they are useful: `needs-info`, `template`, `service`, `upstream`,
`security`, and `blocked`. Start by checking for duplicates and whether the
form contains enough reproduction or upstream information. Runtime reports
such as sidecar healthcheck and database-DNS failures need evidence from the
service, image, Docker/Compose, and Tailscale layers; a formatting-only change
is not proof that they are resolved.
