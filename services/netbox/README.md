# Netbox with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Netbox](https://github.com/github.com/netbox-community) with Tailscale as a sidecar container to securely access your Network layout over a private Tailscale network. By using Tailscale in a sidecar configuration, you can enhance the security and privacy, ensuring that they are only accessible within your Tailscale network.

## Netbox

[Netbox](https://github.com/github.com/netbox-community) exists to empower network engineers. Since its release in 2016, it has become the go-to solution for modeling and documenting network infrastructure for thousands of organizations worldwide. As a successor to legacy IPAM and DCIM applications, NetBox provides a cohesive, extensive, and accessible data model for all things networked.

## Configuration Overview

In this setup, the `tailscale-netbox` service runs Tailscale, which manages secure networking for the Netbox application. The `netbox` application uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This setup ensures that your Netbox application is only accessible through the Tailscale network (or local as well, if preferred).
