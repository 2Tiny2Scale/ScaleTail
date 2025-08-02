# Wallos with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Wallos](https://github.com/ellite/Wallos) with Tailscale as a sidecar container, enabling secure, private access to your self-hosted subscription tracker over your Tailscale network. With this setup, Wallos is never exposed to the public internet—access is limited strictly to devices authenticated through your Tailscale Tailnet.

## Wallos

Wallos is a self-hosted subscription tracking application that helps you manage and visualize your recurring expenses. With a simple and clean interface, Wallos makes it easy to log, track, and analyze your digital subscriptions without relying on any third-party services. Ideal for individuals looking to take control of their finances in a private and minimal environment.

## Key Features

* **Track Subscriptions Easily** – Add services with cost, billing frequency, and renewal dates.

* **Clean, Responsive UI** – Simple and modern interface that works on both desktop and mobile.

* **Visual Budgeting Tools** – View monthly and yearly overviews of your subscription spending.

* **Self-Hosted and Private** – Your data is stored and managed locally.

* **Lightweight Deployment** – Built to run efficiently in Docker with minimal configuration.

* **Private by Default with Tailscale** – Access your Wallos dashboard only from your Tailnet devices.

## Configuration Overview

In this configuration, the `tailscale-wallos` container runs the Tailscale client and joins your private mesh network. The `wallos` container is set to use `network_mode: service:tailscale-wallos`, meaning all of Wallos’s network traffic is routed through the Tailscale container. This ensures that the Wallos interface is not publicly exposed and is only reachable from devices connected to your Tailscale network.

This approach combines self-hosted financial tracking with robust, zero-config VPN security—allowing you to safely manage your subscriptions from anywhere.
