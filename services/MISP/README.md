# MISP with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [MISP](https://github.com/MISP/misp-docker) with Tailscale as a sidecar container to securely access sharing cyber security indicators and threats about cyber security incidents analysis and malware analysis over a private Tailscale network. By using Tailscale in a sidecar configuration, you can enhance the security and privacy of your ThreatIntel, ensuring that they are only accessible within your Tailscale network.

## MISP

[MISP](https://github.com/MISP/MISP) is an open source software solution for collecting, storing, distributing and sharing cyber security indicators and threats about cyber security incidents analysis and malware analysis. MISP is designed by and for incident analysts, security and ICT professionals or malware reversers to support their day-to-day operations to share structured information efficiently.

## Configuration Overview

In this setup, the `tailscale-misp` service runs Tailscale, which manages secure networking for the AdGuard Home service. The `misp` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This setup ensures that AdGuard Home's DNS service is only accessible through the Tailscale network (or local as well, if preferred).

Customize .env based on your needs (optional step)
