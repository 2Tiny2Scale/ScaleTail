# Glance with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Glance](https://github.com/glanceapp/glance) with Tailscale as a sidecar container to securely access your system monitoring dashboard over a private Tailscale network. By using Tailscale in a sidecar configuration, you can enhance the security and privacy of your Glance instance, ensuring that it is only accessible within your Tailscale network.

## Glance

[Glance](https://github.com/glanceapp/glance) is a sleek, real-time dashboard for monitoring your system metrics, Docker containers, and other self-hosted services. It offers a clean and responsive interface that consolidates key system stats and service statuses in one place. This configuration uses Tailscale to securely expose your Glance instance, keeping it protected from the public internet and accessible only within your private Tailscale network.

To install Glance properly, make sure to add the files glance.yml and home.yml to the config folder. The contents of these files can be found [here](https://github.com/glanceapp/docker-compose-template/tree/main/root/config). Also add the file user.css to the assets folder which can be found [here](https://github.com/glanceapp/docker-compose-template/tree/main/root/assets).

## Configuration Overview

In this setup, the `tailscale-glance` service runs Tailscale, which provides secure networking for the Glance service. The `glance` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This ensures that the Glance dashboard is only accessible through the Tailscale network (or locally, if desired), adding a robust layer of privacy and security to your self-hosted monitoring setup.
