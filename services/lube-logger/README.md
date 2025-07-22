# LubeLogger with Tailscale Sidecar Configuration

This Docker Compose configuration sets up **[LubeLogger](https://github.com/hargata/lubelog)** with Tailscale as a sidecar container, enabling secure access to your vehicle maintenance log from anywhere on your private Tailscale network. With this setup, your LubeLogger instance stays completely private and protected, accessible only to your authorized devices.

## LubeLogger

[LubeLogger](https://github.com/hargata/lubelog) is a **self-hosted web app for tracking vehicle maintenance**. Whether you're managing one car or an entire fleet, LubeLogger offers a simple interface to log and monitor oil changes, part replacements, tire rotations, and more. It’s a handy way to maintain service history without relying on third-party platforms or paper logs.

## Key Features

* **Track Maintenance** – Log service events for multiple vehicles.
* **Customizable Entries** – Record any type of maintenance or inspection.
* **Multi-Vehicle Support** – Ideal for families or fleets.
* **Self-Hosted** – Your data, your server.
* **Private by Default with Tailscale** – Runs behind a Tailscale sidecar for private access only.

## Configuration Overview

In this deployment, the `tailscale-lubelogger` service runs the Tailscale client to establish a secure private network. The `lubelogger` container uses `network_mode: service:tailscale-lubelogger` to tunnel its network traffic through the Tailscale network interface. This ensures that the web UI is accessible only through Tailscale, keeping your vehicle data safe from public exposure.
