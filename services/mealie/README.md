# Mealie with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [**Mealie**](https://github.com/mealie-recipes/mealie/) with Tailscale as a sidecar container, enabling secure access to your personal recipe collection and meal planning platform from anywhere on your private Tailscale network. With this setup, your Mealie instance stays fully private and accessible only to your authorized devices.

## Mealie

[**Mealie**](https://github.com/mealie-recipes/mealie/) is a self-hosted recipe management platform designed for home cooks, meal planners, and families. It provides a clean and modern interface to organize, import, and share recipes. Mealie also offers robust tools for planning meals, generating shopping lists, and storing culinary inspiration—all without relying on third-party services.

## Key Features

* **Recipe Management** – Create, edit, and store recipes with rich formatting and images.
* **Recipe Scraping** – Import recipes directly from popular websites.
* **Meal Planning** – Plan meals for the week or month with an easy-to-use calendar view.
* **Shopping List Generator** – Automatically create shopping lists based on your meal plan.
* **Multi-User Support** – Invite family members or housemates to collaborate.
* **Self-Hosted** – All your data remains under your control.
* **Private by Default with Tailscale** – Runs behind a Tailscale sidecar for private access only.

## Configuration Overview

In this deployment, the `tailscale-mealie` service runs the Tailscale client to establish a secure private network. The `mealie` container uses `network_mode: service:tailscale-mealie` to route its network traffic through the Tailscale network interface. This configuration ensures that the web UI is only accessible over Tailscale, protecting your recipes and personal data from public exposure.
