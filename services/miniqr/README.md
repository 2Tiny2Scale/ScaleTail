# Mini-QR with Tailscale Sidecar Configuration  

This Docker Compose configuration sets up **[Mini-QR](https://github.com/lyqht/mini-qr)** with Tailscale as a sidecar container to securely access your self-hosted QR code generation tool over a private Tailscale network. By integrating Tailscale, you can ensure that your Mini-QR instance is only accessible to authorized devices within your private network, adding an extra layer of privacy and security.

## Mini-QR  

[Mini-QR](https://github.com/lyqht/mini-qr) is a **minimalist, self-hosted web app** for quickly generating QR codes on the fly. It features a sleek and simple interface that works well on both desktop and mobile, making it ideal for sharing links, text, or other short data via QR. It’s lightweight, fast, and requires no external services. Pairing it with Tailscale ensures that only trusted devices can access your QR generation tool—perfect for local, secure usage scenarios.

## Key Features  

- **Quick QR Generation** – Instantly generate QR codes from text or URLs.  
- **Mobile-Friendly UI** – Works smoothly on mobile and desktop devices.  
- **No Tracking, No Dependencies** – Lightweight and privacy-respecting.  
- **Self-Hosted** – Full control, no reliance on third-party QR services.  
- **Secure Access with Tailscale** – Limit access to authorized devices via your private network.  

## Configuration Overview  

In this setup, the `tailscale-miniqr` service runs Tailscale, which handles secure networking for the Mini-QR service. The `mini-qr` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This setup ensures that the Mini-QR web interface is only accessible via your Tailscale network (or locally if preferred), giving you complete control over access and visibility.
