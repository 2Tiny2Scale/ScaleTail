# Kavita with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Kavita](https://github.com/Kareadita/Kavita) with Tailscale as a sidecar container to securely serve your comics, manga, and ebooks over a private Tailscale network. By running Tailscale as a sidecar, you restrict access to your Kavita instance to devices authenticated on your Tailnet, avoiding public exposure.

## Kavita

[Kavita](https://github.com/Kareadita/Kavita) is an open-source, self-hosted digital library manager optimized for comics, manga, and ebooks. It provides a modern web UI for browsing collections, reading in-browser, managing metadata, and syncing reading progress across devices. Kavita supports multiple users, libraries, and common archive formats.

## Key Features

* **Library Management** – Organize comics, manga, and ebooks with metadata, tags, and collections.
* **In-Browser Reader** – Read content directly in the browser with smooth navigation and zoom controls.
* **Multi-User Support** – Create accounts with individualized reading progress and permissions.
* **Archive Support** – Handles CBZ, CBR, EPUB, and other common formats.
* **Self-Hosted & Private** – Keep your media on your infrastructure.
* **Private by Default with Tailscale** – Access Kavita only from devices on your Tailnet.

## Configuration Overview

In this setup, the `tailscale-kavita` service runs the Tailscale client to join your private mesh network. The `kavita` service is configured with `network_mode: service:tailscale-kavita`, so all network traffic for Kavita is routed through the Tailscale container. This ensures the web UI and API are reachable only via your Tailscale network (or locally), adding an extra layer of privacy and security to your self-hosted library.

## Files to check

Please verify the following files and variables before deploying:

* `.env` — define SERVICE, IMAGE_URL, SERVICEPORT, TS_AUTHKEY, etc.
* `./config/serve.json` — optional Tailscale Serve configuration if you want to expose specific ports within the Tailnet.
* `./kavita-data` — ensure persistent volumes for libraries and config are correctly mapped.
