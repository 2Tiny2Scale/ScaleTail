# Homepage with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Homepage](https://github.com/gethomepage/homepage) with Tailscale as a sidecar container to securely access your personal dashboard over a private Tailscale network. By using Tailscale in a sidecar configuration, you can enhance the security and privacy of your Homepage instance, ensuring that it is only accessible within your Tailscale network.

## Homepage

[Homepage](https://github.com/gethomepage/homepage) is a modern, customizable, and self-hosted dashboard for organizing and accessing your personal services and information. It integrates with a variety of applications and APIs to display real-time stats, service health, and links in one central interface. This configuration leverages Tailscale to securely connect to your Homepage dashboard, ensuring that your self-hosted interface is protected from unauthorized access and only reachable via your private Tailscale network.

## Configuration Overview

In this setup, the `tailscale-homepage` service runs Tailscale, which manages secure networking for the Homepage service. The `homepage` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This setup ensures that Homepage’s web interface is only accessible through the Tailscale network (or locally, if preferred), providing an extra layer of security and privacy for your self-hosted dashboard.
