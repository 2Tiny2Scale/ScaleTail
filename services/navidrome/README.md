# Navidrome with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Navidrome](https://github.com/navidrome/navidrome) with Tailscale as a sidecar container, enabling secure, private access to your music server over your Tailscale network. With this configuration, Navidrome is never exposed to the public internet, and access is limited to authorized devices on your Tailnet.

## Navidrome

Navidrome is a self-hosted music streaming server and web-based player. It allows you to stream your personal music collection from anywhere, across multiple devices. Compatible with the Subsonic API, it supports a wide range of third-party apps. With a sleek interface, low resource usage, and fast scanning, Navidrome is the ideal solution for building your own private Spotify-like experience.

## Key Features

* **Modern Music Streaming** – Web-based and mobile-friendly interface for streaming your own library.
* **Subsonic API Compatible** – Works with dozens of mobile and desktop apps.
* **Multi-User Support** – Create accounts with individual libraries and permissions.
* **Lightweight & Fast** – Runs well even on low-powered devices.
* **Cross-Platform** – Works on Linux, Windows, macOS, and ARM devices (like Raspberry Pi).
* **Private by Default with Tailscale** – Securely accessible only from your own devices.

## Configuration Overview

In this setup, the `tailscale-navidrome` container runs the Tailscale client and forms a private mesh network. The `navidrome` container is configured with `network_mode: service:tailscale-navidrome`, which routes all of Navidrome’s traffic through Tailscale. This ensures that your music server is never exposed publicly, and can only be accessed from devices authenticated through your Tailscale Tailnet.
