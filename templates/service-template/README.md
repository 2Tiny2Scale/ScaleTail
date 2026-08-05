# SERVICE with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [SERVICE](LINK TO PAGE OF MAINTAINER) with Tailscale as a sidecar container to keep the app reachable over your Tailnet.

## SERVICE

[SERVICE](LINK TO PAGE OF MAINTAINER) information about the service. Explain what the app does in 2-3 sentences and why someone would pair it with Tailscale.

## Configuration Overview

In this setup, the `tailscale-SERVICE` service runs Tailscale, which manages secure networking for SERVICE. The `SERVICE` service utilizes the Tailscale network stack via Docker's `network_mode: service:` configuration. This keeps the app Tailnet-only unless you intentionally expose ports.

## What to document for users

- Prerequisites: note if the host user needs `docker` group membership, GPU/video/render groups, or any devices passed through.
- Volumes: list bind mounts that should be pre-created so Docker does not create root-owned directories; rename any conflicting config folders (for example, `ts-config`) if needed.
- MagicDNS/Serve: when to enable `TS_ACCEPT_DNS`, what to set for `TS_CERT_DOMAIN`, and which port should be in `serve.json` (it does not consume `.env` values automatically).
- Ports: explain whether the commented `0.0.0.0:${SERVICEPORT}:${SERVICEPORT}` mapping is necessary for this app or should stay removed for Tailnet-only access.
- Service-specific gotchas: initial admin setup, default credentials, path expectations, or other quirks to check before first launch.
- Links: include upstream docs for the service and any official setup guides or videos that help users understand the app.

## Files to check

Please check the following contents for validity as some variables need to be defined upfront.

- `.env` // Main variable `TS_AUTHKEY`

## Validation checklist

- Keep the comments and section order from the template Compose and `.env`
  files. Add service-specific comments beside them; do not remove the template
  guidance to make a file shorter.
- Confirm the user-facing container uses `network_mode: service:tailscale` and
  waits for the Tailscale healthcheck.
- Verify the Serve proxy target against the app's actual internal listening
  port. Serve configuration does not consume `.env` port variables.
- Run `python tools/validate_services.py services/<service-name>` and
  `docker compose config --quiet` from this service directory before opening a
  pull request.
