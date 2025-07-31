# FossFLOW with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [FossFLOW](https://github.com/stan-smith/FossFLOW) with Tailscale as a sidecar container, enabling secure access to your self-hosted, visual workflow builder over your private Tailscale network. With this setup, your FossFLOW instance stays protected and accessible only from authorized devices on your Tailnet.

## FossFLOW

FossFLOW is a free and open-source, drag-and-drop workflow automation platform. Inspired by tools like n8n and Node-RED, it lets you visually create, edit, and execute automation pipelines with a clean and modern interface. FossFLOW is built with speed and usability in mind and is ideal for developers, makers, and self-hosters looking to automate tasks with full control and privacy.

## Key Features

* **Visual Workflow Builder** – Design automations with a modern drag-and-drop UI.
* **Local-First Execution** – All workflows run locally, no external cloud involved.
* **Modular Node System** – Integrate with APIs, databases, and file systems.
* **Persistent Storage** – Workflows and states are saved and restored automatically.
* **Open Source & Lightweight** – Easy to deploy and extend.
* **Private by Default with Tailscale** – Keep your automations secure and off the public web.

## Configuration Overview

In this setup, the `tailscale-fossflow` container runs the Tailscale client and establishes a secure tunnel. The `fossflow` container uses `network_mode: service:tailscale-fossflow` so that all its traffic routes through the Tailscale interface. This ensures that your FossFLOW instance is only reachable from devices connected to your Tailscale network—no public IP exposure, no complex firewall rules.
