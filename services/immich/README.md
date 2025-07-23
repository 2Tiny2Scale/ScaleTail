# Immich with Tailscale Sidecar Configuration

This Docker Compose configuration sets up Immich with Tailscale as a sidecar container, enabling secure access to your photo and video library from anywhere on your private Tailscale network. With this setup, your Immich instance remains completely private and protected, accessible only to your authorized devices.

**Please note** Immich changes the [docker-compose](https://immich.app/docs/install/docker-compose) often, we try to match the docker-compose in this repo to theirs, but make sure to check for yourself.

## Immich

Immich is a self-hosted, high-performance solution for backing up and browsing photos and videos from your mobile devices. It offers a sleek interface, automatic uploads, facial recognition, albums, search, and metadata support—all while keeping your media under your control. Immich is a privacy-first alternative to commercial cloud-based photo services, ideal for individuals or families.

## Key Features

* **Automatic Uploads** – Sync photos and videos from mobile devices instantly.
* **Albums & Timeline** – Organize and view media in an intuitive gallery.
* **Face Recognition & Object Detection** – Smart tools to tag and sort images.
* **Multi-User Support** – Share with family while maintaining user boundaries.
* **Self-Hosted** – Run on your own server with full control.
* **Private by Default with Tailscale** – Secured with Tailscale, accessible only to you.

## Configuration Overview

In this deployment, the `tailscale-immich` service runs the Tailscale client to establish a secure private network. The `immich` container uses `network_mode: service:tailscale-immich` to route its traffic through the Tailscale interface. This ensures that the Immich web UI and backend services are only reachable via your Tailscale network, keeping your personal media safe from public exposure.
