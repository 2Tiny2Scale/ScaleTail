# NewWallpaperWhoDis with Tailscale Sidecar Configuration

This Docker Compose configuration sets up **NewWallpaperWhoDis** with a Tailscale sidecar container, enabling secure, private access to your self-hosted wallpaper manager over your Tailnet. With this setup, your NewWallpaperWhoDis instance is **not exposed to the public internet** and is only accessible from authorized devices connected via Tailscale.

## NewWallpaperWhoDis

[**NewWallpaperWhoDis**](https://github.com/upioneer/NewWallpaperWhoDis) is a lightweight, self-hosted wallpaper manager designed to turn browsers, tablets, smart TVs, Raspberry Pis, dashboards, and other display endpoints into dynamic smart displays. It uses a simple flat-file workflow, so wallpaper collections can be managed by placing images into directories instead of maintaining a traditional database-heavy media system.

The application scans your wallpaper files, processes useful metadata such as aspect ratio, orientation, and luminosity, and serves wallpapers through configurable rotation profiles. This makes it useful for dashboards, wall-mounted displays, digital signage-style setups, home labs, offices, and any environment where you want centrally managed wallpaper rotation without manually touching each display.

## Key Features

- 🖼️ Self-hosted wallpaper management for displays and browser-based endpoints
- 📁 Flat-file image library workflow with simple folder-based collection management
- 🔄 Dynamic wallpaper rotation through customizable profiles
- 🧭 Central web interface for managing wallpapers and endpoints
- 📺 Suitable for smart TVs, tablets, dashboards, Raspberry Pis, and kiosk-style screens
- 🧩 Lightweight deployment without a traditional relational database requirement
- 🔐 Tailnet-only access when paired with the included Tailscale sidecar

## Usage Notes

For display devices such as smart TVs, tablets, or dashboards, open the relevant NewWallpaperWhoDis player URL in a browser. Once the endpoint is connected, wallpaper behavior can be managed centrally from the web interface without needing to reconfigure the device directly.

## References

- [NewWallpaperWhoDis Website](https://newwallpaperwhodis.web.app/)
- [NewWallpaperWhoDis GitHub Repository](https://github.com/upioneer/NewWallpaperWhoDis)
- [Tailscale Docker Documentation](https://tailscale.com/kb/1282/docker)
