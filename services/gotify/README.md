# Gotify with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Gotify](https://github.com/gotify/server) with Tailscale as a sidecar container, enabling secure access to your notification server from anywhere on your private Tailscale network. With this setup, your Gotify instance remains completely private and protected, accessible only to your authorized devices.

## Gotify

[Gotify](https://github.com/gotify/server) is a simple server for sending and receiving messages in real-time. It's a self-hosted solution perfect for getting notifications from various services directly to your device. Gotify is lightweight, easy to set up, and designed to work seamlessly with your existing infrastructure.

## Key Features

* **Real-Time Notifications** – Receive instant messages from your applications.
* **Simple Setup** – Easy to deploy and configure.
* **Customizable Clients** – Works with multiple clients on different platforms.
* **Self-Hosted** – Full control over your notification data.
* **Private by Default with Tailscale** – Secured with Tailscale, accessible only to you.

## Configuration Overview

In this deployment, the `tailscale-gotify` service runs the Tailscale client to establish a secure private network. The `gotify` container uses `network_mode: service:tailscale-gotify` to route its traffic through the Tailscale interface. This ensures that the Gotify web UI and backend services are only reachable via your Tailscale network, keeping your notifications safe from public exposure.
