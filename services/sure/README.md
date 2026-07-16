# Sure with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Sure](https://github.com/we-promise/sure) with Tailscale as a sidecar container, enabling secure, private access to your self-hosted personal finance platform over your Tailnet. With this setup, your Sure instance is **not exposed to the public internet** and is only reachable from authorized devices connected via Tailscale.

## Sure

[**Sure**](https://sure.am) is a self-hosted personal finance application and a community-maintained fork of the now-archived Maybe Finance project. It is an all-in-one platform for tracking bank accounts, monitoring stocks and crypto holdings, and following your overall net worth — all from a single interface with multi-currency support.

Sure is built on Ruby on Rails and is designed for individuals and households that want full ownership of their financial data instead of relying on cloud-hosted finance apps. It includes transaction and portfolio tracking alongside optional AI-assisted features, while remaining fully self-hostable with Docker.

## Key Features

- 📊 Net worth tracking across all of your accounts
- 💳 Bank, credit card, and cash transaction management
- 📈 Stocks and cryptocurrency portfolio monitoring
- 💱 Multi-currency support for international finances
- 🤖 Optional AI features (chat, rules) via OpenAI integration
- 🔐 Optional OpenID Connect (OIDC) single sign-on
- 🔑 WebAuthn MFA support for passkeys and hardware security keys
- 🛡️ Tailnet-only access when paired with the included Tailscale sidecar

## Configuration Overview

Sure is a **multi-container application**. This stack runs the following services on a dedicated `sure_net` Docker bridge network alongside the Tailscale sidecar:

- **web** – the main Rails web application (`ghcr.io/we-promise/sure:stable`), serving the Sure UI on port `3000`.
- **worker** – a Sidekiq background worker (same image, run with `bundle exec sidekiq`) that processes asynchronous jobs.
- **db** – a PostgreSQL 16 database storing all Sure data.
- **redis** – a Redis instance used as the Sidekiq queue and cache.
- **backup** *(optional, behind the `backup` profile)* – a scheduled PostgreSQL backup container.

The `tailscale` service authenticates to your Tailnet and provides the private network endpoint. The `web` and `worker` containers share the Tailscale container's network namespace using Docker's `network_mode: service:tailscale` pattern, so they reach the Tailnet directly and publish no ports to the host.

### Hybrid networking

This stack uses a hybrid networking approach so that Tailscale and Sure's support containers can coexist:

- `web` and `worker` use `network_mode: service:tailscale` (Tailnet-only).
- `db`, `redis`, and `backup` run on the `sure_net` bridge network with static IPs.
- The `tailscale` container is attached to `sure_net` so its network namespace can reach the database and Redis.

Because **MagicDNS is enabled** (`TS_ACCEPT_DNS=true`), Tailscale overrides Docker's embedded DNS inside the `web`/`worker` namespace. This means `web` and `worker` **cannot resolve container names** like `db` or `redis`, so they connect to the database and Redis using their static IPs (`DB_HOST=172.28.0.10`, `REDIS_URL=redis://172.28.0.11:6379/1`) defined in the `.env` file. The `backup` container sits directly on `sure_net`, so it can still use Docker DNS (`POSTGRES_HOST=db`).

## Before You Start

Review and edit the `.env` file before launching the stack. Several values must be set correctly for the app to run and to remain secure:

- **`TS_AUTHKEY`** – required; generate an auth key at <https://tailscale.com/admin/authkeys>.
- **`SECRET_KEY_BASE`** – required and **empty by default**. Generate a unique value with `openssl rand -hex 64` and paste it.
- **`POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB`** – the defaults (`sure_user` / `sure_password` / `sure_production`) are placeholders and should be changed before deploying for production use.
- **`DB_HOST`, `REDIS_URL`, `POSTGRES_HOST`** – leave as-is unless you change the static IPs or network layout described above.
- **`TZ`** – set to your local time zone.

### Bind mount directories

The compose file bind-mounts several host directories. Pre-create them so Docker does not create them as root-owned:

```bash
mkdir -p config ts/state app-storage postgres-data redis-data backups
```

## HTTPS / SSL Settings

The `.env` ships with `RAILS_FORCE_SSL=true` and `RAILS_ASSUME_SSL=true`. Because Tailscale Serve terminates TLS in front of the app, `RAILS_ASSUME_SSL=true` is what tells Rails the connection is secure even though Serve forwards to it over plain HTTP on port `3000`. If you access Sure directly over HTTP through the Tailnet and encounter redirect issues, set both values back to `false`.

## Troubleshooting

If stock price or exchange-rate syncs fail with `Failed to open TCP connection to fc.yahoo.com`, DNS is likely resolving Yahoo Finance to IPv6 first, which the container can't reach. Upstream forces IPv4 DNS (`dns: [8.8.8.8, 1.1.1.1]`) on `web`/`worker`; this stack omits it because their DNS is handled by Tailscale (MagicDNS). For the recommended workarounds, see the note in the [Sure Docker self-hosting guide](https://github.com/we-promise/sure/blob/main/docs/hosting/docker.md).

## Optional Integrations

### OpenAI (AI features)

Sure can use OpenAI for AI-powered features such as chat and rules. Set `OPENAI_ACCESS_TOKEN` in `.env` to enable it. **Enabling OpenAI will incur costs on your OpenAI account**, so set appropriate spend limits before adding it. See the [Sure AI documentation](https://github.com/we-promise/sure/blob/main/docs/hosting/ai.md).

### OpenID Connect (OIDC)

Sure supports OIDC for external authentication providers such as Google, GitHub, Keycloak, Authentik, Okta, or Azure AD. Fill in `OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, and `OIDC_REDIRECT_URI` in the `.env` file to enable it. The redirect URI should follow the pattern `https://<your-domain>/auth/openid_connect/callback`. See the [Sure OIDC documentation](https://github.com/we-promise/sure/blob/main/docs/hosting/oidc.md).

### WebAuthn MFA (passkeys)

If you enable passkeys, Touch ID, Windows Hello, or hardware security keys as MFA credentials, pin the WebAuthn relying party settings (`WEBAUTHN_RP_ID` and `WEBAUTHN_ALLOWED_ORIGINS`) in your environment before registering any passkeys. See the [WebAuthn configuration guide](https://github.com/we-promise/sure/blob/main/docs/hosting/webauthn.md).

## Usage Notes

Start the core stack with:

```bash
docker compose up -d
```

On first launch, open the Sure URL on your Tailnet and click **create your account** to register the initial user. There are no default admin credentials — the first account you create becomes your login.

To run the optional scheduled database backups, include the backup profile:

```bash
docker compose --profile backup up -d
```

Backups are written to the `./backups` directory by default; adjust the retention settings (`SCHEDULE`, `BACKUP_KEEP_DAYS`, `BACKUP_KEEP_WEEKS`, `BACKUP_KEEP_MONTHS`) in `.env` as needed.

## References

- [Sure Website](https://sure.am)
- [Sure GitHub Repository](https://github.com/we-promise/sure)
- [Sure Docker Self-Hosting Guide](https://github.com/we-promise/sure/blob/main/docs/hosting/docker.md)
- [Sure OIDC Documentation](https://github.com/we-promise/sure/blob/main/docs/hosting/oidc.md)
- [Sure AI Documentation](https://github.com/we-promise/sure/blob/main/docs/hosting/ai.md)
- [Sure WebAuthn Documentation](https://github.com/we-promise/sure/blob/main/docs/hosting/webauthn.md)
- [Tailscale Docker Documentation](https://tailscale.com/kb/1282/docker)
