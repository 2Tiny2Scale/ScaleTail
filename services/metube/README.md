# Metube with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Metube](https://github.com/alexta69/metube) with Tailscale as a sidecar container to securely manage and access your self-hosted bookmark manager over a private Tailscale network. By integrating Tailscale, you can ensure that your Linkding instance remains private and accessible only to authorized devices on your Tailscale network.

## Metube

[Metube](https://github.com/alexta69/metube) is a self-hosted YouTube downloader with playlist support. Allows you to download videos from YouTube and dozens of other sites.

## Configuration Overview

In this setup, the `tailscale-metube` service runs Tailscale, which manages secure networking for the metube application. The `metube` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This ensures that metube’s web interface is only accessible through the Tailscale network (or locally, if preferred), providing enhanced privacy and security.
