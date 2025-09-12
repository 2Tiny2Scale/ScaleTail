# Forgejo with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [**Forgejo**](https://forgejo.org/) with Tailscale as a sidecar container, enabling secure access to your self-hosted Git service from anywhere on your private Tailscale network. With this setup, your Forgejo instance remains fully private and accessible only from authorized devices.

## Forgejo

[**Forgejo**](https://forgejo.org/) is a community-driven, self-hosted Git service inspired by the Esperanto word for *forge*. Designed as a lightweight and independent alternative to monopoly platforms, Forgejo offers Git hosting along with rich collaboration and project management tools. It is actively developed and governed by an open community, promising **Independent Free/Libre Software forever**.

## Key Features

* **Lightweight Deployment** – Runs smoothly on nearly any machine, from Raspberry Pi to cloud instances.
* **Project Management** – Built-in issues, pull requests, wikis, and kanban boards for seamless teamwork.
* **Publishing Tools** – Host software releases or publish via the built-in package registry (Docker, npm, etc.).
* **Customizable & Flexible** – Tweak configuration switches to adapt Forgejo to your exact needs.
* **Advanced Capabilities** – Organizations, permissions, CI/CD integration, code search, LDAP/OAuth support.
* **Privacy-First** – Minimal tracking and safe defaults to protect users and their data.
* **Federation (WIP)** – Ongoing work on ActivityPub integration to connect forges into a wider network.
* **Free & Open Source** – Licensed under GPL-3.0+, ensuring transparency and community ownership.

## Configuration Overview

In this deployment, the `tailscale-forgejo` service runs the Tailscale client to establish a secure private network. The `forgejo` container uses `network_mode: service:tailscale-forgejo` to route all traffic through the Tailscale interface. This ensures your Git service, web interface, and API endpoints are only accessible via Tailscale, preventing public exposure while still offering seamless remote access to your team.

## Reference Material

* [Youtube.com - Own Your Code Forever - A Private Git Server Setup Guide with Tailscale and Forgejo](https://www.youtube.com/watch?v=JcrcbkDGJuk)
