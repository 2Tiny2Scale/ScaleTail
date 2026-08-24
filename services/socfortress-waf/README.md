# SOCFortress WAF with Tailscale (admin UI on your Tailnet)

This adds a Tailscale sidecar to the [SOCFortress WAF Management Platform](https://github.com/socfortress/waf-platform-public) so the **admin UI is reachable only over your Tailnet** at `https://<host>.<your-tailnet>.ts.net`, with a valid HTTPS certificate. The **WAF data plane is left exactly as upstream ships it** — `caddy-waf` still listens on host ports **80/443** so it can front your protected sites with automatic per-site Let's Encrypt certs and see real client IPs.

Funnel (public internet exposure) is **intentionally disabled**.

## About this setup

The WAF platform is a six-service stack (Caddy+Coraza engine, FastAPI admin API, React/Nginx admin UI, PostgreSQL, Redis, and a demo upstream). Only one piece — the **admin console** — benefits from being private-by-default, and that is exactly what a WAF operator wants: keep the control panel off the public internet, reach it securely from anywhere over Tailscale. The Tailscale container joins the stack's `waf-internal` network as a normal peer and reverse-proxies to `admin-ui:8080` by its Docker DNS name. Nothing about how the WAF protects traffic changes.

## Architecture

- `tailscale` (from `compose.tailscale.yml`): joins your Tailnet, terminates HTTPS on `:443` using the node's `*.ts.net` certificate, and proxies to the admin UI. **Tailnet-only** (`AllowFunnel: false`).
- `admin-ui`: serves the console on internal `:8080` over HTTPS with a self-signed cert. The sidecar reaches it via `https+insecure://admin-ui:8080` (the public-facing `*.ts.net` cert is valid, so your browser sees no warning).
- `caddy-waf` and the rest of the stack: unchanged. Data plane stays on host `80/443`.

Access the admin UI at: `https://<TS_HOSTNAME>.<your-tailnet>.ts.net` (after first auth + HTTPS enabled in your tailnet).

## Quick-ish Start

1. Drop these four files into the cloned `waf-platform` directory (next to the upstream `docker-compose.yml`):
   - `.env`, `compose.yml`, `compose.tailscale.yml`, `README.md`
2. Copy and edit the env file:
   ```bash
   cp .env .env   # already named .env here; edit it in place
   ```
   Fill every `CHANGE_ME`, set a real `TS_AUTHKEY`, and set `ALLOWED_ORIGINS` to your Tailnet URL (see [Gotchas](#important-notes--gotchas)). Generate secrets with:
   ```bash
   openssl rand -hex 32                                                        # POSTGRES_PASSWORD
   python3 -c "import secrets; print(secrets.token_hex(32))"                   # SECRET_KEY
   python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"  # TOTP_ENCRYPTION_KEY
   ```
3. (Recommended) Make the admin UI **Tailnet-only** by removing its host port. In the upstream `docker-compose.yml`, comment out the two `ports:` lines under the `admin-ui` service:
   ```yaml
     admin-ui:
       ...
       # ports:
       #   - "8443:8080"
   ```
   Leave them in if you also want LAN access on `https://<host>:8443`.
4. Validate (see [Linting](#linting--validation)), then start everything:
   ```bash
   docker compose up -d
   docker compose ps
   docker compose logs -f tailscale     # watch for "Logged in as..." and serve config applied
   ```
5. Find your node's URL (`tailscale status` inside the container, or the Tailscale admin console). It will be `https://<TS_HOSTNAME>.<your-tailnet>.ts.net`.
6. Make sure `ALLOWED_ORIGINS` in `.env` matches that exact URL, then apply it:
   ```bash
   docker compose up -d admin-api
   ```
7. From any device on your Tailnet, open `https://<TS_HOSTNAME>.<your-tailnet>.ts.net`, log in with the bootstrap admin, change the password, and enroll TOTP.

## Important Notes & Gotchas

- **CORS is the #1 thing people miss.** The admin API rejects origins not in `ALLOWED_ORIGINS` (no wildcard). When you move login to the Tailnet URL, you **must** set `ALLOWED_ORIGINS=https://<TS_HOSTNAME>.<your-tailnet>.ts.net` and recreate `admin-api`. Symptoms if you forget: the page loads but login/API calls fail.
- **Enable HTTPS in your tailnet** (Admin console → DNS → MagicDNS + HTTPS Certificates). Without it, Tailscale Serve cannot provision the `*.ts.net` certificate and the serve config is skipped. Public DNS for a fresh tailnet name can take up to ~10 minutes.
- **Self-signed backend is expected.** The admin UI's internal cert is self-signed, so the sidecar uses `https+insecure://admin-ui:8080`. Your browser still sees a valid Let's Encrypt cert because Tailscale terminates TLS at the edge with the `*.ts.net` cert.
- **The data plane is still public.** `caddy-waf` keeps listening on host `80/443`. Point DNS for the sites you protect at this host as you normally would; Caddy's automatic per-site TLS and GeoIP/client-IP features are unaffected. Tailscale is only in front of the admin UI.
- **Updating:** `docker compose pull && docker compose up -d`. Data lives in named volumes and survives updates. The Tailscale node identity persists in the `tailscale-state` volume.

## Files

- `.env` — all WAF variables + the Tailscale section (`TS_AUTHKEY` is critical; keep private).
- `compose.yml` — orchestrator; `include`s the upstream stack and the sidecar. Auto-selected by `docker compose`.
- `compose.tailscale.yml` — the Tailscale sidecar service + inline serve config.
- `docker-compose.yml` — upstream, unchanged (provided by the cloned repo; not in this bundle).

## Upstream Documentation

- [SOCFortress WAF repo](https://github.com/socfortress/waf-platform-public)
- [Tailscale Serve](https://tailscale.com/kb/1242/tailscale-serve) · [Tailscale + Docker guide](https://tailscale.com/blog/docker-tailscale-guide)
- [Enabling HTTPS in your tailnet](https://tailscale.com/kb/1153/enabling-https)

## Troubleshooting

- **`serve proxy: no serve config ... skipping`** — HTTPS isn't enabled in your tailnet yet, or the config file path is wrong. Enable HTTPS, then `docker compose up -d tailscale`. If it persists, switch from the inline `configs:` block to a bind-mounted file: create `./config/serve.json` with the same JSON (use literal `${TS_CERT_DOMAIN}`), and mount `./config:/config` on the `tailscale` service.
- **Browser cert warning / no page** — the `*.ts.net` cert may still be provisioning (wait a few minutes), or HTTPS isn't enabled in the tailnet.
- **502 / connection refused at the `.ts.net` URL** — `admin-ui` not healthy yet (`docker compose ps`), or its internal port isn't 8080; check `docker compose logs admin-ui`.
- **Login/API fails after the page loads** — `ALLOWED_ORIGINS` doesn't match the Tailnet URL. Fix `.env` and `docker compose up -d admin-api`.
- **No Tailnet IP** — auth key expired/invalid, or ACL/tag restrictions; check `docker compose logs tailscale`.

---
