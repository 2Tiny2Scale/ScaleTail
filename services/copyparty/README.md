# Copyparty with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Copyparty](https://github.com/9001/copyparty) with Tailscale as a sidecar container to securely access your lightweight file server and sharing platform over a private Tailscale network. By using Tailscale in a sidecar configuration, you can enhance the security and accessibility of your Copyparty instance, ensuring it is only available within your Tailscale network.

## Copyparty

[Copyparty](https://github.com/9001/copyparty) is a versatile, self-contained file server that runs on virtually any system. It supports file uploads, downloads, media streaming, WebDAV, and even full-on public or private file sharing with user authentication. Designed to be fast and lightweight, it requires no external dependencies and is extremely customizable. With this setup, Copyparty is exposed only to your Tailscale network, providing secure, peer-to-peer access from your devices.

**Key Features:**

- 📤 Drag-and-drop uploads via the browser
- 📁 Directory listing and browsing
- 🔒 User authentication and permissions
- 🌐 WebDAV support for file mounts and syncing
- 🎵 Audio/video streaming with built-in media player
- 📝 Built-in text editor and image previews
- 🧩 Single binary, no dependencies required
- 🖥️ Runs on any OS, including Linux, Windows, macOS, and even Android
- 🔧 Highly configurable with powerful CLI flags and config options

With Tailscale in place, all of these features are securely tunneled through your private mesh network—no need to expose ports to the public internet.

## Configuration Overview

In this setup, the `tailscale-copyparty` service runs Tailscale, which handles the secure networking layer. The `copyparty` service uses Docker’s `network_mode: service:` setting to share the network stack of the Tailscale container. This means the Copyparty web interface and all file sharing functionality are only accessible via the Tailscale network (or locally if preferred), adding a strong privacy layer to your self-hosted file server.
