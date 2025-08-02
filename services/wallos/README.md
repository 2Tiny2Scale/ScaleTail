# Wallos with Tailscale Sidecar Configuration

This Docker Compose configuration sets up **Wallos** with a **Tailscale sidecar container**. This allows you to securely access your personal bill management tool over a private Tailscale network. By integrating Tailscale this way, you can ensure your Wallos instance is only accessible within your private network, adding a crucial layer of security and privacy to your sensitive financial data.

---

## Wallos

[Wallos](https://github.com/ellite/wallos) is a free, open-source web application designed to help you track subscriptions and recurring payments. Since Wallos handles sensitive financial data, keeping it secure is critical. By using Tailscale, you can securely access your self-hosted Wallos instance from any of your devices, ensuring your financial information remains private and inaccessible to unauthorized users.

---

## Configuration Overview

In this setup, the `tailscale-wallos` service runs Tailscale, which manages the secure networking for the Wallos service. The `wallos` service then uses the Tailscale network stack through Docker's `network_mode: "service:tailscale-wallos"` configuration. This ensures that Wallos is only accessible through your Tailscale network (or locally, if you prefer). This configuration provides a private and secure way to manage your finances, protected from external access or data breaches.
