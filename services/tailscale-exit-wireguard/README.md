# Tailscale Exit Node with WireGuard (ProtonVPN) Sidecar

This Docker Compose configuration sets up a Tailscale Exit Node that routes all traffic through a WireGuard VPN tunnel (e.g., ProtonVPN). Devices on your Tailscale network can use this node as an exit point, ensuring all their internet traffic is encrypted and routed through your VPN provider.

## Architecture

```
Device → Tailscale Exit Node → WireGuard (ProtonVPN) → Internet
```

- **WireGuard** runs the ProtonVPN tunnel as a VPN client
- **Tailscale** advertises itself as an exit node, routing traffic through WireGuard
- When you select this exit node on any Tailscale device, your traffic flows through ProtonVPN

## Configuration Overview

### WireGuard Service

- Uses `linuxserver/wireguard` image to run the ProtonVPN WireGuard tunnel as a **client**
- Requires your ProtonVPN WireGuard config file at `./wireguard/config/wg0.conf`
- No ports are exposed - WireGuard connects outbound to ProtonVPN only
- Handles IP forwarding and NAT for VPN traffic

### Tailscale Exit Node

- Uses `network_mode: service:wireguard` to share WireGuard's network namespace
- Advertises itself as an exit node via `--advertise-exit-node`
- All Tailscale traffic is routed through the WireGuard tunnel

## Setup Instructions

### 1. Get a Tailscale Auth Key

1. Go to [Tailscale Admin](https://login.tailscale.com/admin/settings/keys)
2. Generate a new auth key
3. Set `TS_AUTHKEY` in the `.env` file

### 2. Get Your ProtonVPN WireGuard Config

1. Go to [ProtonVPN Dashboard](https://account.protonvpn.com/vpn/dashboard)
2. Download the WireGuard configuration for your desired server
3. Create the config directory and place the file:

```bash
mkdir -p wireguard/config
cp /path/to/your/protonvpn-wg0.conf ./wireguard/config/wg0.conf
```

### 3. Configure Environment Variables

Edit the `.env` file with your settings:

| Variable | Description | Default |
|----------|-------------|---------|
| `TS_AUTHKEY` | Tailscale auth key (required) | - |
| `TZ` | Timezone | `Europe/Amsterdam` |

### 4. Enable Exit Node on Tailscale

After starting the stack:

1. Go to [Tailscale Admin](https://login.tailscale.com/admin/machines)
2. Find your exit node machine
3. Click the `...` menu → **Edit route settings**
4. Enable the exit node

### 5. Use the Exit Node

On any Tailscale device:

```bash
# Linux/macOS
tailscale up --exit-node=<exit-node-name>

# Or select it in the Tailscale app UI
```

## File Structure

```
tailscale-exit-wireguard/
├── compose.yaml          # Docker Compose configuration
├── .env                  # Environment variables
├── README.md             # This file
├── wireguard/
│   └── config/
│       └── wg0.conf      # Your ProtonVPN WireGuard config
└── ts/
    └── state/            # Tailscale state (auto-created)
```

## Troubleshooting

### WireGuard not connecting

- Verify your `wg0.conf` is valid: `docker compose exec wireguard cat /config/wg0.conf`
- Check WireGuard logs: `docker compose logs wireguard`
- Ensure the config file has no BOM or Windows line endings

### Tailscale not advertising exit node

- Check Tailscale status: `docker compose exec tailscale tailscale status`
- Verify exit node is enabled in Tailscale admin panel
- Check Tailscale logs: `docker compose logs tailscale`

### Health check failing

- WireGuard health check runs `wg show wg0` to verify the interface is up
- Tailscale health check hits `http://127.0.0.1:41234/healthz`
- Both services must be healthy for the stack to work correctly
