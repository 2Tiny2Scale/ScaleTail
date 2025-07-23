# Coder with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [**Coder**](https://github.com/coder/coder) with Tailscale as a sidecar container, enabling secure access to your self-hosted cloud development environments from anywhere on your private Tailscale network. With this setup, your Coder instance remains fully private and accessible only from authorized devices.

## Coder

[**Coder**](https://github.com/coder/coder) is an open-source, self-hosted platform that allows developers to define, provision, and secure web-based IDE workspaces (e.g., code-server, Jupyter) on cloud or local infrastructure. Environments are managed via Terraform templates, automatically shutdown when idle, and accessible through a browser or local IDE—perfect for teams or individuals seeking reproducible, isolated dev environments without cloud vendor lock-in.

## Key Features

* **Terraform-Based Environments** – Provision Docker, VM, Kubernetes workspaces via versioned infrastructure.
* **Browser & Local IDE Support** – Use in-browser VS Code or connect via local VS Code / JetBrains.
* **Auto-Scaling & Idle Shutdown** – Automatically stop idle workspaces to optimize resource usage.
* **AI & Agent Integration** – Designed to support AI coding agents and secure development workflows.
* **Self-Hosted & Secure** – Keep full control on your infrastructure, behind your firewall.
* **Private by Default with Tailscale** – Runs behind a Tailscale sidecar for private access only.

## Configuration Overview

In this deployment, the `tailscale-coder` service runs the Tailscale client to establish a secure private network. The `coder` container uses `network_mode: service:tailscale-coder` to route all traffic through the Tailscale interface. This ensures that your development environments, admin UI, and web IDEs are only accessible via Tailscale, preventing public exposure.
