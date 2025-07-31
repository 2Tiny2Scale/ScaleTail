# FossFLOW with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [FossFLOW](https://github.com/stan-smith/FossFLOW) with Tailscale as a sidecar container, enabling secure access to your visual workflow designer over your private Tailscale network. With this setup, FossFLOW remains fully self-hosted and is only accessible from authorized devices within your Tailnet.

## FossFLOW

FossFLOW is a free and open-source flow **visualization** tool. Unlike automation platforms like n8n or Node-RED, FossFLOW is focused purely on building and displaying visual representations of workflows—**not executing them**. It’s ideal for planning complex automations, designing data pipelines, or documenting logic in a clear, drag-and-drop interface.

## Key Features

* **Flow Visualizer** – Build directed graphs and flows using an intuitive UI.
* **No Execution** – FossFLOW is for visualization only, not for running workflows.
* **Node-Based Editor** – Easily represent logic, data sources, APIs, and more.
* **Export & Share** – Save flows as JSON and share them with others.
* **No Telemetry** – Fully local with zero tracking or analytics.
* **Secure with Tailscale** – Only accessible from your private Tailscale network.

## Configuration Overview

This setup includes a `tailscale-fossflow` container running the Tailscale client to establish a secure connection. The `fossflow` container uses `network_mode: service:tailscale-fossflow`, ensuring all traffic routes through Tailscale. This keeps your flow diagrams accessible only to authenticated devices within your Tailnet, with no exposure to the public internet.
