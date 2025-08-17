# Subtrackr with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [**Subtrackr**](https://github.com/bscott/subtrackr) with Tailscale as a sidecar container, enabling secure access to your self-hosted subscription tracking platform from anywhere on your private Tailscale network. With this setup, your Subtrackr instance remains fully private and accessible only from authorized devices.

## Subtrackr

[**Subtrackr**](https://github.com/bscott/subtrackr) is an open-source, self-hosted web application for managing and tracking recurring subscriptions. It provides a clean, modern interface to help you monitor costs, renewal dates, and payment methods across all your services. Designed for individuals and households, Subtrackr makes it easy to stay on top of your digital and physical subscriptions without relying on third-party services.

## Key Features

* **Centralized Subscription Management** – Keep all your recurring subscriptions organized in one place.
* **Expense Tracking** – Monitor total spending, breakdowns, and trends across services.
* **Renewal Reminders** – Stay informed with upcoming renewal and billing notifications.
* **Service Categorization** – Group subscriptions by category for clear overviews (e.g., streaming, utilities, software).
* **Payment Method Tracking** – Associate subscriptions with credit cards, bank accounts, or other payment methods.
* **Responsive Web Interface** – A simple, mobile-friendly UI for adding and reviewing subscriptions.
* **Self-Hosted & Open Source** – Run Subtrackr on your own infrastructure with Docker, ensuring privacy and data ownership.

## Configuration Overview

In this deployment, the `tailscale-subtrackr` service runs the Tailscale client to establish a secure private network. The `subtrackr` container uses `network_mode: service:tailscale-subtrackr` to route all traffic through the Tailscale interface. This ensures that your subscription data, dashboards, and administration interface are only accessible via Tailscale, preventing public exposure.
