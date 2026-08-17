# Nextcloud with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Nextcloud](https://github.com/nextcloud/docker) with Tailscale as a sidecar container to securely access your files and collaboration tools over your Tailnet. By using Tailscale in a sidecar configuration, you get automatic HTTPS with a URL like `https://nextcloud.your-tailnet.ts.net` without exposing anything to the public internet.

## Nextcloud

[Nextcloud](https://nextcloud.com) is a self-hosted platform for file sync, sharing, and collaboration. It provides a web interface for documents, calendars, contacts, and media, along with desktop and mobile apps for all major platforms. When paired with Tailscale, your Nextcloud instance becomes accessible across all your trusted devices through your secure Tailnet, with no need for port forwarding or complex reverse proxy configurations.

## Configuration Overview

In this setup, the `tailscale-nextcloud` service runs Tailscale, which manages secure networking for the Nextcloud stack. The `nextcloud`, `db`, and `redis` services all use the Tailscale network stack via Docker's `network_mode: service:` configuration. This keeps your entire Nextcloud stack Tailnet-only unless you intentionally expose ports.

This stack includes four containers:
- **Tailscale** - Manages networking and exposes Nextcloud via Tailscale Serve with automatic HTTPS
- **Nextcloud** - The application server (Apache image, port 80)
- **MariaDB** - Database backend (LTS release)
- **Redis** - Caching and file locking to prevent performance issues

## Prerequisites

- Docker and Docker Compose installed
- A Tailscale auth key from the [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
- Your host user should be in the `docker` group

## Getting Started

1. Copy `templates/service-template` into `services/nextcloud` (or clone this repo)
2. Edit the `.env` file and set strong passwords for:
   - `MYSQL_ROOT_PASSWORD`
   - `MYSQL_PASSWORD`
   - `NEXTCLOUD_ADMIN_PASSWORD`
3. Set your Tailscale auth key in `TS_AUTHKEY`
4. Run `docker compose up -d`
5. Access Nextcloud at `https://nextcloud.your-tailnet.ts.net` from any device on your Tailnet

## Trusted Domains

The `NEXTCLOUD_TRUSTED_DOMAINS` variable in `compose.yaml` is set to `${SERVICE}.tail12345.ts.net` by default. You should update this to match your actual Tailscale domain. You can find your domain in the Tailscale Admin Console under **DNS** settings.

## Volumes

| Volume | Purpose |
|--------|---------|
| `./nextcloud-data/html` | Nextcloud application and configuration files |
| `./nextcloud-data/db` | MariaDB database files |

Pre-creating these directories is optional; Docker will create them automatically with root ownership.

## Files to check

Please check the following contents for validity as some variables need to be defined upfront.

- `.env`
  - Required: `TS_AUTHKEY`
  - Required: `MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD`, `NEXTCLOUD_ADMIN_PASSWORD` - change all from defaults

## Upstream Documentation

- [Nextcloud Docker Documentation](https://github.com/nextcloud/docker)
- [Nextcloud Admin Manual](https://docs.nextcloud.com/server/latest/admin_manual/)
- [Nextcloud Docker Compose Examples](https://github.com/nextcloud/docker#usage)
