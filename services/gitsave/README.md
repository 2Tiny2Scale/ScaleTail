# GitSave with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [**GitSave**](https://github.com/TimWitzdam/GitSave) with Tailscale as a sidecar container, enabling secure access to your self-hosted GitHub repository backup solution from anywhere on your private Tailscale network. With this setup, your GitSave instance remains fully private and accessible only from authorized devices.

## GitSave

[**GitSave**](https://github.com/TimWitzdam/GitSave) is a self-hosted tool for automatically backing up your GitHub repositories. It runs as a lightweight web service with a simple REST API and can be scheduled or triggered manually. Designed for developers, teams, and organizations who want to keep a secure copy of their code outside GitHub, GitSave ensures your projects remain safe and accessible under your own control.

## Key Features

* **Automated Backups** – Regularly back up all your GitHub repositories with minimal setup.
* **REST API Interface** – Trigger backups or manage configurations programmatically.
* **Simple Configuration** – Connect with your GitHub account via a personal access token.
* **Dockerized Deployment** – Run in a containerized environment for easy setup and portability.
* **Lightweight & Fast** – Written in Go for speed and efficiency with minimal resource usage.
* **Self-Hosted & Secure** – Maintain full control of your backup data on your own infrastructure.

## Configuration Overview

In this deployment, the `tailscale-gitsave` service runs the Tailscale client to establish a secure private network. The `gitsave` container uses `network_mode: service:tailscale-gitsave` to route all traffic through the Tailscale interface. This ensures that your GitHub backup service and its API endpoints are only accessible via Tailscale, preventing public exposure.
