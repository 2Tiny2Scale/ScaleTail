# ConvertX with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [ConvertX](https://github.com/C4illin/ConvertX) with Tailscale as a sidecar container to securely access your media conversion tool over a private Tailscale network. By using Tailscale in a sidecar configuration, you can enhance the security and privacy of your ConvertX instance, ensuring that it is only accessible within your Tailscale network.

## ConvertX

[ConvertX](https://github.com/C4illin/ConvertX) is a self-hosted, user-friendly media conversion tool designed to automate the process of converting media files using hardware acceleration where available. It supports batch conversion and integrates smoothly with media server workflows. This setup uses Tailscale to expose your ConvertX instance only to trusted devices within your private Tailscale network, keeping the web interface protected from public access.

## Configuration Overview

In this setup, the `tailscale-convertx` service runs Tailscale, which manages secure networking for the ConvertX service. The `convertx` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This ensures that ConvertX’s web interface is only accessible through the Tailscale network (or locally, if preferred), providing an additional layer of security and privacy for your self-hosted media conversion workflow.
