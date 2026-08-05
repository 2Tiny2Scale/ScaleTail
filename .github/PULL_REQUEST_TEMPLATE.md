# Servicename: context
<!-- Examples: Dockhand: new service | Changedetection: fix port mapping -->

## Description
<!-- Briefly describe what changed. -->

## Related Issues
<!-- Link any related issues (e.g. Fixes #123). Use "None" if not applicable. -->

- None.

## Verification
<!-- Describe how you tested this change and include relevant proof such as logs, command output, or screenshots if useful. -->

## Checklist

- [ ] I have performed a self-review of my code and followed the [templates](https://github.com/tailscale-dev/ScaleTail/tree/main/templates/service-template) structure.
- [ ] I have added verification that the stack works as expected.
- [ ] I have updated necessary documentation (e.g. frontpage [README.md](https://github.com/tailscale-dev/ScaleTail/blob/main/README.md) ).
- [ ] I have selected the correct label(s) for this PR.
- [ ] I preserved the template comments and ran `python tools/validate_services.py` plus `docker compose config --quiet` for each changed service.
- [ ] For a new service, I checked official upstream documentation for the image, internal port, healthcheck, volumes, permissions, dependencies, and architecture support.

## Additional Context
<!-- Any extra info for reviewers, such as gotchas, special requirements, devices, or dependencies. Use "None" if not applicable. -->

- None.
