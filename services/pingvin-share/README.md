# Pingvin Share with Tailscale Sidecar Configuration

**PLEASE NOTE** As per June 29, 2025 pingvin-share **has been archived** by the developer.

This Docker Compose configuration sets up [Pingvin Share](https://github.com/stonith404/pingvin-share) with Tailscale as a sidecar container to securely share files over a private Tailscale network. By using Tailscale in a sidecar configuration, you can ensure your file-sharing instance is accessible only within your Tailscale network, providing enhanced security and privacy.

## Pingvin Share

[Pingvin Share](https://github.com/stonith404/pingvin-share) is a simple, open-source file-sharing application designed to make sharing files quick, easy, and efficient. It supports drag-and-drop uploads, expiring links, and a user-friendly web interface. With this setup, Tailscale ensures that your Pingvin Share instance remains secure and private, limiting access to only authorized devices on your Tailscale network.

## Configuration Overview

In this setup, the `tailscale-pingvin` service runs Tailscale, which manages secure networking for the Pingvin Share service. The `pingvin-share` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This ensures that Pingvin Share’s web interface and file-sharing capabilities are only accessible through the Tailscale network (or locally, if preferred), providing an extra layer of security and privacy for your self-hosted file-sharing needs.
