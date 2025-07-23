# Docmost with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [**Docmost**](https://github.com/docmost/docmost) with Tailscale as a sidecar container, enabling secure access to your collaborative wiki and documentation platform from anywhere on your private Tailscale network. With this setup, your Docmost instance remains fully private and accessible only to authorized users.

## Docmost

[**Docmost**](https://github.com/docmost/docmost) is an open-source, self-hosted wiki and documentation tool designed for teams that want real-time collaboration without vendor lock-in. It offers a sleek interface with support for rich editing, diagrams, permissions, inline comments, page history, and file attachments.

## Key Features

* **Real-Time Collaboration** – Multiple users can edit simultaneously with live syncing.
* **Diagrams & Math** – Support for Mermaid, Draw\.io, Excalidraw, and LaTeX.
* **Structured Content** – Organize documentation in spaces, nested pages, and groups.
* **Permissions & Comments** – Enforce role-based access while enabling inline discussion.
* **Page History & Export** – View history, revert changes, and import/export Markdown/HTML.
* **Full-Text Search** – Quickly locate documentation across all content.
* **File Attachments** – Embed images, PDFs, and other files.
* **Privacy-first & Self-Hosted** – Keep all data under your control behind Tailscale.

## Configuration Overview

In this configuration, the `tailscale-docmost` service runs the Tailscale client to secure network traffic. The `docmost` service uses `network_mode: service:tailscale-docmost`, ensuring all requests are routed through the Tailscale interface. This safeguards your documentation from public exposure, making it accessible only within your private mesh.
