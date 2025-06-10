# Overseerr with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Overseerr](https://github.com/sct/overseerr) with Tailscale as a sidecar container to securely manage and access your request management system over a private Tailscale network. By integrating Tailscale in a sidecar configuration, you enhance the privacy and security of your Overseerr instance, ensuring it is only accessible within your Tailscale network.

## Overseerr

[Overseerr](https://github.com/sct/overseerr) is an open-source request management and media discovery tool built to work with Plex and Jellyfin. It allows users to search and request media, track request status, and manage users in a visually appealing and user-friendly interface. By pairing Overseerr with Tailscale, your instance becomes securely accessible through a zero-config mesh VPN, preventing unauthorized access over the public internet.

## Configuration Overview

In this setup, the `tailscale-overseerr` service runs the Tailscale daemon to provide secure, private networking. The `overseerr` service is configured to use Tailscale’s network stack via Docker’s `network_mode: service:` syntax. This binds Overseerr’s network interface to the Tailscale container, making the web UI and API available only through your Tailscale network (or locally, if needed).

This architecture is ideal for self-hosters who want to access Overseerr from anywhere without exposing it to the internet, maintaining both ease of access and strict privacy controls.
