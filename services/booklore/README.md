# BookLore with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [BookLore](https://github.com/booklore-app/booklore) with Tailscale as a sidecar container to securely access and manage your book library over a private Tailscale network. By integrating Tailscale, you can ensure that your BookLore instance remains private and accessible only to devices within your Tailscale network.

## BookLore

[BookLore](https://github.com/booklore-app/booklore) is an open-source self-hosted application for managing and reading books. It offers features like multi-user support, Kobo & KOReader sync and support for many formats.

## Configuration Overview

In this setup, the `tailscale-booklore` service runs Tailscale, which manages secure networking for the BookLore service. The `booklore` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This ensures that BookLore’s web interface are only accessible through the Tailscale network (or locally, if preferred), providing an extra layer of security and privacy.
