# Mail Archiver with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Mail Archiver](https://mail-archiver.org/) with Tailscale as a sidecar container to keep the app reachable over your Tailnet.

## Mail Archiver

[Mail Archiver](https://mail-archiver.org/) is an open-source and self hosted email archiver with powerful features, including a wide array of email sources (IMAP, M365, import files), a powerful search feature scanning email metadata and content and the ability to sync all your mailboxes to your account.
This configuration leverages Tailscale to securely connect to your Mail Archiver instance, ensuring that your email archiving interface is protected from unauthorized access and that your instance is accessible only via your private Tailscale network.


## Configuration Overview

In this setup, the `tailscale-mailarchive-app` service runs Tailscale, which manages secure networking for Mail Archiver. The `mailarchive-app` service utilizes the Tailscale network stack via Docker's `network_mode: service:` configuration. This keeps the app Tailnet-only unless you intentionally expose ports.
