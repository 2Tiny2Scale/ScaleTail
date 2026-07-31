# ArtistTrackarr with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [ArtistTrackarr](https://github.com/crypt0rr/ArtistTrackarr) with Tailscale as a sidecar container, keeping the application securely reachable over your Tailnet without exposing it directly to the public internet.

## ArtistTrackarr

[ArtistTrackarr](https://github.com/crypt0rr/ArtistTrackarr) is a self-hosted household dashboard that monitors MusicBrainz and, optionally, Spotify for newly announced and released albums and EPs. It can send announcement and release-day notifications through Email, Discord, Telegram, ntfy, Gotify, generic webhooks, and other services supported by Shoutrrr.

Pairing ArtistTrackarr with Tailscale provides private access to its web interface from authorized Tailnet devices without requiring public port forwarding or a publicly accessible reverse proxy.

## Configuration Overview

In this setup, the `tailscale-artist-trackarr` service runs Tailscale and manages secure networking for ArtistTrackarr. The `artist-trackarr` service uses the Tailscale container's network stack through Docker's `network_mode: service:tailscale-artist-trackarr` configuration.

ArtistTrackarr listens on port `8080`. Because both containers share the same network namespace, Tailscale Serve can forward traffic directly to `http://127.0.0.1:8080`.

This keeps ArtistTrackarr Tailnet-only unless you intentionally publish its port on the Docker host.

## Good to Know

- **Container permissions:** The ArtistTrackarr image runs as UID and GID `10001`. When using a bind-mounted host directory for `/data`, create it before starting the stack and make it writable by UID and GID `10001`:

  ```console
  mkdir -p ./artist-trackarr-data
  sudo chown -R 10001:10001 ./artist-trackarr-data
  ```

  Incorrect ownership can prevent ArtistTrackarr from creating or opening its SQLite database.

- **Volumes:** ArtistTrackarr stores its SQLite database, cached Cover Art Archive artwork, and other persistent application data in `/data`. The upstream deployment uses the legacy-named `artist-tracker-data` Docker volume for compatibility with existing installations.

- **Required application configuration:** Before starting ArtistTrackarr, define the following values:

  - `SETUP_TOKEN`
  - `APP_ENCRYPTION_KEY`
  - `SESSION_SECRET`
  - `MUSICBRAINZ_CONTACT`
  - `PUBLIC_URL`

  `SETUP_TOKEN`, `APP_ENCRYPTION_KEY`, and `SESSION_SECRET` should each contain a random value of at least 32 characters. `MUSICBRAINZ_CONTACT` must contain a real email address or project URL because it is included in the MusicBrainz API User-Agent.

- **Public URL:** Set `PUBLIC_URL` to the HTTPS address through which users will access ArtistTrackarr over Tailscale, for example:

  ```env
  PUBLIC_URL=https://artist-trackarr.example-tailnet.ts.net
  ```

- **Polling interval:** The default `POLL_INTERVAL` is `6h`. Values below one hour are rejected by the application.

- **Spotify integration:** Spotify integration is optional. Configure `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`, and an appropriate two-letter `SPOTIFY_MARKET`, such as `NL`, to enable Spotify-first artist discovery and an additional release-observation feed.

- **Reverse-proxy handling:** Tailscale Serve acts as the HTTPS reverse proxy in this deployment. Set `TRUST_PROXY=true` only when ArtistTrackarr should trust forwarded client-address headers from the proxy.

- **Backups:** Stop ArtistTrackarr before backing up its persistent `/data` directory or Docker volume to ensure a consistent SQLite backup. Database migrations run automatically when the application is upgraded.

- **Official links:**
  - [ArtistTrackarr repository](https://github.com/crypt0rr/ArtistTrackarr)
  - [Shoutrrr documentation](https://containrrr.dev/shoutrrr/)
  - [MusicBrainz](https://musicbrainz.org/)
  - [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
