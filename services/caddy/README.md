# Caddy with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Caddy](https://github.com/caddyserver/caddy-docker) with Tailscale as a sidecar container to securely manage and route your traffic over a private Tailscale network. By integrating Tailscale, you can enhance the security and privacy of your Caddy instance, ensuring that access is restricted to devices within your Tailscale network.

## Caddy

[Caddy](https://github.com/caddyserver/caddy-docker) is an extensible platform for deploying long-running services ("apps") using a single, unified configuration. It is enterprise-ready, extensible, open source, and provides automatic HTTPS. By incorporating Tailscale, your Caddy instance is safeguarded, ensuring that only authorized users and devices on your Tailscale network can access your applications and services.

## Configuration Overview

In this setup, the `tailscale-caddy` service runs Tailscale, which manages secure networking for the Caddy service. The `caddy_proxy` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This ensures that Caddy’s dashboard and routing functionalities are only accessible through the Tailscale network (or locally, if preferred), adding an extra layer of privacy and security to your network architecture.

To get this working:

- Update the FQDN in `Caddyfile` to match your `${SERVICE}.MagicDNSname.ts.net`.
- Update the TS_AUTHKEY in the .env file to your Tailscale key.

If you change the `SERVICE=caddy` line in the .env file, the hostname of the FQDN in the Caddyfile must be updated as well. Additionally please replace $SERVICE in docker-compose.yml services:caddy_proxy:healthcheck with the string caddy.

The example `docker-compose.yml` uses a simple webserver for testing purposes.

Within your Tailscale dashboard do you have [HTTPS](https://tailscale.com/kb/1153/enabling-https) and [MagicDNS](https://tailscale.com/kb/1081/magicdns) enabled? If so, remove the http:// from the Caddyfile and Caddy should automatically provision a public HTTPS certificate from Let's Encrypt via the Tailscale infrastructure. The certificate takes ~20s to be procured upon first visit. This is further documented in [Caddy certificates on Tailscale](https://tailscale.com/kb/1190/caddy-certificates).
