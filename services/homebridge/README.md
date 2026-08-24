# homebridge with Tailscale Sidecar

This Docker Compose configuration sets up [Homebridge](https://github.com/homebridge/homebridge) with Tailscale as a sidecar container. Homebridge emulates the iOS HomeKit API, enabling HomeKit integration for non-Apple smart home devices. The Homebridge UI is reachable **only over your Tailnet** via HTTPS.

## ⚠️ Critical Limitation

**Homebridge requires `host` network mode for HomeKit mDNS discovery.** This sidecar configuration isolates Homebridge into a separate network namespace, which **breaks HomeKit discovery entirely**. HomeKit clients will not be able to find or control your devices.

**What works:**
- Access the Homebridge UI web interface over HTTPS via Tailnet: `https://homebridge.your-tailnet.ts.net`
- Install plugins, edit config, view logs
- Full remote administration

**What doesn't work:**
- HomeKit device discovery on your local network
- HomeKit app integration from iPhone/iPad
- Siri control via HomeKit

If you need HomeKit discovery, run Homebridge with `network_mode: host` instead (standard Docker setup, no Tailscale sidecar). If you only need the web UI for administration from Tailnet, proceed with this configuration.

## About Homebridge

Homebridge is a lightweight Node.js server that emulates the HomeKit API. It translates between HomeKit and non-HomeKit smart home devices (Philips Hue, IKEA TRADFRI, etc.), allowing them to integrate into the Apple Home ecosystem. This image includes FFmpeg with libfdk-aac for camera streaming support.

## Architecture

- `tailscale`: Runs the Tailscale client, obtains a Tailnet IP, serves HTTPS on :443 proxying to Homebridge UI on internal port 8581.
- `homebridge`: Runs in the **same network namespace** as the tailscale container. Configuration and plugins persist in a dedicated volume.

Access the UI at: `https://homebridge.your-tailnet.ts.net` (after auth and healthy state).

## Prerequisites

- Docker & Docker Compose v2.20+
- Tailscale account + ability to create auth keys
- Host user in `docker` group (or use sudo)
- Pre-create volume directories (recommended):
  ```bash
  mkdir -p homebridge-data/config ts-homebridge-state
  ```

## First Run & Setup

On first boot, Homebridge generates a unique setup code in the logs. Find it with:
```bash
docker compose logs homebridge | grep -i "setup code"
```

You'll use this code if setting up HomeKit bridges (only if HomeKit discovery were enabled). For web UI access, no setup code is needed.

## Configuration

### Important Notes

- **ENABLE_AVAHI=0**: Avahi (mDNS daemon) is disabled since the sidecar network prevents proper mDNS broadcasts. HomeKit discovery is not functional in this setup.
- **Tailscale Serve**: The sidecar automatically proxies port 443 to the Homebridge UI on 8581. HTTPS certificates are auto-provisioned by Tailscale.
- **Plugins**: Install via the Homebridge UI. They persist in the mounted volume.

### Optional Environment Variables

Add to `compose.yml` under the `homebridge` service `environment:` block if needed:
- `HB_PORT=8581` — Web UI port (change if desired, but update compose.tailscale.yml Proxy port to match)

## Upstream Documentation

- [Homebridge GitHub](https://github.com/homebridge/homebridge)
- [Homebridge Docker Guide](https://github.com/homebridge/homebridge/wiki/Install-Homebridge-on-Docker)
- [Homebridge Plugins](https://www.npmjs.com/search?q=homebridge-plugin)
- [Homebridge UI](https://github.com/homebridge/homebridge-config-ui-x)
- [Tailscale Docker Guide](https://tailscale.com/blog/docker-tailscale-guide)

## Troubleshooting

- **Container unhealthy**: Check `docker compose logs tailscale` and `docker compose logs homebridge`
- **Can't reach UI over HTTPS**: Verify Tailscale connection with `docker compose exec tailscale tailscale status`. If not logged in, check TS_AUTHKEY.
- **UI timeout or 502**: Ensure Homebridge is running with `docker compose logs homebridge`. Check that internal port 8581 is correct.
- **HomeKit discovery not working**: This is expected. The sidecar breaks mDNS. Run with `network_mode: host` for full HomeKit support.