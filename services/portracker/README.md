# Portracker with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Portracker](https://github.com/mostafa-wahied/portracker) with Tailscale as a sidecar container to securely access your lightweight port monitoring and tracking tool over a private Tailscale network. By using Tailscale in a sidecar configuration, you can enhance the security and accessibility of your Portracker instance, ensuring it is only available within your Tailscale network.

## Portracker

[Portracker](https://github.com/mostafa-wahied/portracker) is a simple, self-hosted port monitoring tool that helps you keep track of open ports on your servers. It provides a web interface for viewing, searching, and exporting port information, making it easy to audit and manage your network exposure. Portracker is lightweight, easy to deploy, and requires minimal configuration. With this setup, Portracker is exposed only to your Tailscale network, providing secure, peer-to-peer access from your devices.

**Key Features:**

- 🔍 Real-time port monitoring and listing
- 📊 Export port data to CSV for audits
- 🖥️ Simple web interface for browsing and searching
- 🛡️ Helps identify open ports and potential vulnerabilities
- ⚡ Lightweight and fast deployment
- 🔧 Minimal configuration required

With Tailscale in place, all of these features are securely tunneled through your private mesh network—no need to expose ports to the public internet.

## Configuration Overview

In this setup, the `tailscale-portracker` service runs Tailscale, which handles the secure networking layer. The `portracker` service uses Docker’s `network_mode: service:` setting to share the network stack of the Tailscale container. This means the Portracker web interface and all monitoring functionality are only accessible via the Tailscale network (or locally if preferred), adding a strong privacy layer to your self-hosted port tracker.
