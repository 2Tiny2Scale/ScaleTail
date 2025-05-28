# AdGuardHome Sync with Tailscale Sidecar Configuration

This Docker Compose configuration sets up **[AdGuardHome Sync](https://github.com/bakito/adguardhome-sync)** with Tailscale as a sidecar container to securely synchronize your AdGuard Home instances over a private Tailscale network. By integrating Tailscale, you ensure that configuration data is transmitted securely between nodes and accessible only to authorized devices in your private network.

## AdGuardHome Sync

[AdGuardHome Sync](https://github.com/bakito/adguardhome-sync) is a **lightweight tool for synchronizing configuration between multiple AdGuard Home servers**. It supports syncing DNS settings, clients, rules, rewrites, and more—making it ideal for managing AdGuard Home across multiple networks or locations. Whether you're managing redundant setups or simply keeping home and remote deployments in sync, this tool helps you maintain consistency and saves time.

## Key Features

* **Multi-Node Syncing** – Keep multiple AdGuard Home instances in sync effortlessly.
* **Granular Configuration** – Choose which parts of the configuration to sync (rules, clients, rewrites, etc.).
* **Push or Pull Modes** – Use a master-push or node-pull strategy to fit your setup.
* **Self-Hosted** – Fully local, no third-party service required.
* **Secure Access with Tailscale** – Safely connect and sync instances across private networks using Tailscale.

## Configuration Overview

In this setup, the `tailscale-adguardhome-sync` service runs Tailscale, which manages secure networking for the AdGuardHome Sync service. The `adguardhome-sync` container uses the Tailscale network stack via Docker’s `network_mode: service:` configuration. This ensures that all sync communication is confined to your private Tailscale network, preventing exposure to the public internet.
