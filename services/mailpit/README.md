# Mailpit with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Mailpit](https://mailpit.axllent.org/) with Tailscale as a sidecar container. The Mailpit web interface is available privately over your Tailnet through Tailscale Serve and automatic HTTPS, while SMTP remains publicly reachable on host TCP port `25` so external mail servers can deliver messages.

## Mailpit

[Mailpit](https://mailpit.axllent.org/) is a lightweight email capture and inspection tool with a modern web interface. It accepts SMTP messages, stores them locally, and lets you inspect rendered content, headers, raw source, and attachments without requiring individual mailbox accounts.

This deployment restricts accepted recipients with `MAIL_DOMAIN_REGEX`, allowing every address at a configured domain to be collected as a catch-all inbox. Mailpit does not send or relay captured mail unless relay functionality is configured separately.

## Configuration Overview

In this setup, the `tailscale-mailpit` container runs Tailscale and owns the shared network namespace. The `mailpit` service uses Docker's `network_mode: service:tailscale` configuration, allowing Tailscale Serve to proxy the Mailpit web interface from `127.0.0.1:8025` to HTTPS on your Tailnet.

Only SMTP is published on the Docker host:

- Mailpit web interface: Tailnet-only through Tailscale Serve on HTTPS port `443`
- Incoming SMTP: public host TCP port `25`, forwarded to Mailpit TCP port `1025`
- Tailscale Funnel: disabled

## Key Features

- Catch-all email capture for a configurable domain
- Private web interface with Tailscale HTTPS
- Public SMTP delivery on the standard TCP port `25`
- Persistent SQLite message storage
- Configurable message count, age, and size limits
- Health checks for both Tailscale and Mailpit
- No outbound mail relay configured by default

Some hosting providers block inbound or outbound SMTP traffic. Confirm that TCP port `25` is permitted before deploying this service.

## Environment Configuration

Update `.env` before starting the containers. The following values are required by `compose.yaml`:

| Variable                   | Description                                               | Example                      |
| -------------------------- | --------------------------------------------------------- | ---------------------------- |
| `MAIL_DOMAIN_REGEX`        | Regular expression matching allowed recipients            | `'@example\.com$'`           |
| `MAILPIT_MAX_MESSAGES`     | Maximum stored messages; `0` disables count-based pruning | `0`                          |
| `MAILPIT_MAX_AGE`          | Maximum message age in hours or days                      | `90d`                        |
| `MAILPIT_MAX_MESSAGE_SIZE` | Maximum accepted message size in MB                       | `50`                         |

For a different domain, escape dots in the regular expression. For example, use `'@mail\.example\.com$'` to accept every recipient ending in `@mail.example.com`.

## DNS Configuration

Create an address record for the mail host and point the domain's MX record to it. Replace the example values with your public hostname and IP address:

```dns
mail.example.com.    A     203.0.113.10
example.com.         MX 10 mail.example.com.
```

The MX target must resolve directly to the Docker host, and TCP port `25` must be forwarded through any external firewall or router. Do not proxy the mail hostname through an HTTP-only reverse proxy or CDN.

## Security Considerations

SMTP is intentionally exposed to the public internet without mailbox authentication so external mail servers can deliver messages. `MAIL_DOMAIN_REGEX` limits accepted recipients, but Mailpit is primarily an email testing and inspection tool rather than a full production mail server. Keep the web interface private, use firewall rules where appropriate, apply updates regularly, and avoid storing sensitive mail longer than necessary.

## Files to Check

Please check the following files before deployment:

- `.env` — service images, Tailscale auth key, recipient restriction, and retention settings
- `compose.yaml` — public SMTP binding, Tailscale Serve configuration, and storage paths

## Reference Material

- [Mailpit documentation](https://mailpit.axllent.org/docs/)
- [Mailpit runtime options](https://mailpit.axllent.org/docs/configuration/runtime-options/)
- [Mailpit email storage](https://mailpit.axllent.org/docs/configuration/email-storage/)
