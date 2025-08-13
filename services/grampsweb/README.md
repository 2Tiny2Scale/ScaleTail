# Gramps Web with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [**Gramps Web**](https://github.com/gramps-project/gramps-web) with Tailscale as a sidecar container, enabling secure access to your self-hosted genealogy platform from anywhere on your private Tailscale network. With this setup, your Gramps Web instance remains fully private and accessible only from authorized devices.

## Gramps Web

[**Gramps Web**](https://github.com/gramps-project/gramps-web) is an open-source, self-hosted web application for collaborative browsing and editing of genealogical data. It provides a modern, mobile-friendly interface to your family tree, with full interoperability with the Gramps Desktop application. Designed for individuals, families, and research groups, Gramps Web makes it easy to share, visualize, and enrich family history data while keeping full control over your information.

## Key Features

* **Collaborative Editing** – Multiple users can view and edit the same family tree with role-based permissions.
* **Interactive Charts and Maps** – Explore family relationships through dynamic ancestor, descendant, and hourglass charts, plus integrated mapping with historical overlays.
* **AI-Powered Chat** – Ask questions about your family tree using natural language, with AI providing context-aware answers.
* **Media and Face Tagging** – Store and manage media files, with automatic face detection and tagging to link people to photos.
* **Search and Reporting** – Perform full-text searches and generate printable reports directly in the browser.
* **Bi-Directional Sync with Gramps Desktop** – Keep online and offline databases in sync using the Gramps Web Sync add-on.
* **Privacy Controls** – Mark individuals or events as private and filter sensitive data from public views.
* **Self-Hosted & Open Source** – Run on your own infrastructure with Docker, keeping your data under your control.

## Configuration Overview

In this deployment, the `tailscale-grampsweb` service runs the Tailscale client to establish a secure private network. The `grampsweb` container uses `network_mode: service:tailscale-grampsweb` to route all traffic through the Tailscale interface. This ensures that your genealogy database, charts, and administration interface are only accessible via Tailscale, preventing public exposure.
