# FreshRSS with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [FreshRSS](https://freshrss.org/) with Tailscale as a sidecar container, enabling secure access to your self-hosted feed reader over a private Tailscale network. With this setup, your FreshRSS instance remains fully private and accessible only from devices on your Tailnet, over HTTPS.

## FreshRSS

[FreshRSS](https://github.com/FreshRSS/FreshRSS) is a self-hosted RSS and Atom feed aggregator. It is lightweight, powerful, and customizable through themes and extensions. It exposes a Google Reader-compatible and Fever-compatible API, so clients such as Reeder, NetNewsWire, Unread, and FeedMe can sync against your own server.

## Key Features

- **Self-Hosted Feed Reading** – Your subscriptions, read state, and article archive stay on your own hardware.
- **Third-Party Client Sync** – Google Reader and Fever compatible APIs let third-party apps sync with your instance.
- **Extensible** – A large catalog of community themes and extensions.
- **Built-in Refresh Cron** – Feeds can be refreshed on a schedule inside the container, no host cron required.
- **Low Resource Usage** – Runs comfortably on a Raspberry Pi with the default SQLite database.
- **Private by Default with Tailscale** – No public exposure, no reverse proxies or port forwarding, and HTTPS handled by Tailscale Serve.

## Configuration Overview

In this deployment, the `tailscale-freshrss` service runs the Tailscale client and joins your Tailnet as the host `freshrss`. The `app-freshrss` service uses `network_mode: service:tailscale`. That means both containers share one network namespace. Tailscale Serve terminates HTTPS on port 443 and proxies to FreshRSS on `127.0.0.1:80` inside that shared namespace.

## Prerequisites

- Docker and the Compose plugin, with your user in the `docker` group (or use `sudo`).
- `/dev/net/tun` available on the host and the `NET_ADMIN` capability, both already declared in `compose.yaml`.
- A Tailscale [auth key](https://console.tailscale.com/admin/settings/keys) from the web admin console (**Settings → Keys → Generate auth key**). Set it to "Pre-Approved" if that option appears. The key is used only for the initial registration — with `TS_AUTH_ONCE=true` and the persisted `ts/state` volume, restarts reuse the stored node state — so a single-use key is sufficient. Tagging the device disables key expiry, which avoids re-authentication after the default 180 days.
- HTTPS certificates [enabled for your Tailnet](https://console.tailscale.com/admin/dns) (**DNS → HTTPS Certificates**). Tailscale Serve cannot issue a certificate without it, and the container will start but never serve.

## Files to check

Please verify the following files and variables before deploying:

- `.env` — set `TS_AUTHKEY`, `TAILNET_NAME`, `TZ`, `ADMIN_USERNAME`, `ADMIN_PASSWORD`, `ADMIN_API_PASSWORD`, and `ADMIN_EMAIL`.
- `compose.yaml` — confirm the volume paths and the `Proxy` port in the `ts-serve` config.

## Usage Notes

- **First run only.** `FRESHRSS_INSTALL` and `FRESHRSS_USER` drive FreshRSS's unattended installer, and only take effect while the data directory is empty. On later starts the entrypoint reports `FreshRSS already installed; no change performed.` and ignores `.env`. Set the passwords before the first `docker compose up` and change them from the FreshRSS UI afterwards, not by editing `.env`. Avoid `$`, backticks, and backslashes in those first-run values — Compose and the entrypoint both interpret them.
- **`TAILNET_NAME` feeds the base URL.** `compose.yaml` builds `--base-url` as `https://${SERVICE}.${TAILNET_NAME}`, so include the `.ts.net` suffix. FreshRSS displays the value read-only under **Configuration → System**; to change it after the first run, use `docker compose exec application ./cli/reconfigure.php --base-url https://freshrss.example.ts.net`.
- **Health check.** The app health check runs `./cli/health.php`, which ships with the image and requests `/api/`. Disabling the API in the UI will mark the container unhealthy even though the web interface works.
- **Ports.** The `ports` block stays commented out; the Tailnet is the only way in. Uncommenting it publishes plain HTTP on the host and bypasses Tailscale entirely. Note `SERVICEPORT` is `80`, which often collides on the host.
- **MagicDNS.** Uncomment `TS_ACCEPT_DNS=true` only if the container itself must resolve other MagicDNS names, such as an external database. It is not needed for the default SQLite setup.

## References

- [FreshRSS website](https://freshrss.org/)
- [FreshRSS on GitHub](https://github.com/FreshRSS/FreshRSS)
- [FreshRSS Docker documentation](https://github.com/FreshRSS/FreshRSS/blob/edge/Docker/README.md)
- [FreshRSS extensions](https://github.com/FreshRSS/Extensions)
- [Tailscale Serve documentation](https://tailscale.com/kb/1242/tailscale-serve)
- [Tailscale auth keys](https://tailscale.com/kb/1085/auth-keys)
