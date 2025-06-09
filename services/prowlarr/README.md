# Prowlarr with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Prowlarr](https://github.com/Prowlarr/Prowlarr) with Tailscale as a sidecar container to securely manage and access your indexer management system over a private Tailscale network. By using Tailscale in a sidecar configuration, you can enhance the security and privacy of your Prowlarr instance, ensuring that it is only accessible within your Tailscale network.

## Prowlarr

[Prowlarr](https://github.com/Prowlarr/Prowlarr) is an open-source, self-hosted application that acts as an indexer manager for popular media automation tools such as Radarr, Sonarr, Lidarr, and Readarr. It supports a wide variety of torrent and Usenet indexers, consolidating their configuration into one place. This configuration leverages Tailscale to securely connect to your Prowlarr instance, ensuring that your indexer management interface is protected from unauthorized access and that your instance is only accessible via your private Tailscale network.

## Configuration Overview

In this setup, the `tailscale-prowlarr` service runs Tailscale, which manages secure networking for the Prowlarr service. The `prowlarr` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This setup ensures that Prowlarr’s web interface and API are only accessible through the Tailscale network (or locally, if preferred), providing an extra layer of security and privacy for your self-hosted indexer manager.
