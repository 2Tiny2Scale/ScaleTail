# Traefik with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Traefik](https://github.com/traefik/traefik) with Tailscale as a sidecar container to securely manage and route your traffic over a private Tailscale network. By integrating Tailscale, you can enhance the security and privacy of your Traefik instance, ensuring that access is restricted to devices within your Tailscale network.

## Traefik

[Traefik](https://github.com/traefik/traefik) is a modern, open-source reverse proxy and load balancer that simplifies the deployment and management of services in dynamic environments. It supports a wide range of integrations with container orchestration platforms and cloud providers, offering features like automatic HTTPS, load balancing, and monitoring. By incorporating Tailscale, your Traefik instance is safeguarded, ensuring that only authorized users and devices on your Tailscale network can access your applications and services.

## Configuration Overview

In this setup, the `tailscale-traefik` service runs Tailscale, which manages secure networking for the Traefik service. The `traefik` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This ensures that Traefik’s dashboard and routing functionalities are only accessible through the Tailscale network (or locally, if preferred), adding an extra layer of privacy and security to your network architecture.
