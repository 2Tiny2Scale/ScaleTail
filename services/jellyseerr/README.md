# Jellyseerr with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Jellyseerr](https://docs.jellyseerr.dev/) with Tailscale as a sidecar container to securely manage and access your request management system over a private Tailscale network. By integrating Tailscale in a sidecar configuration, you enhance the privacy and security of your Jellyseerr instance, ensuring it is only accessible within your Tailscale network.

## Jellyseerr

[Jellyseerr](https://docs.jellyseerr.dev/) is an open-source request management and media discovery tool built to work with Jellyfin and Plex. The primary motivation for starting Jellyseerr was to bring Jellyfin and Emby support to Overseerr. However, over time, Jellyseerr has evolved into its own distinct application with unique features. Designed as a one-stop shop for media requests, it offers a simple, easy-to-use experience for managing requests on Jellyfin, Emby, and Plex servers.

## Configuration Overview

In this setup, the `tailscale-jellyseerr` service runs the Tailscale daemon to provide secure, private networking. The `jelly` service is configured to use Tailscale’s network stack via Docker’s `network_mode: service:` syntax. This binds Jellyseerr’s network interface to the Tailscale container, making the web UI and API available only through your Tailscale network (or locally, if needed).

This architecture is ideal for self-hosters who want to access Jellyseerr from anywhere without exposing it to the internet, maintaining both ease of access and strict privacy controls.
