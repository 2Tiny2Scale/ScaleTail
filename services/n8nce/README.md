# N8N with Tailscale Sidecar Configuration  

This Docker Compose configuration sets up **[N8N Community Edition](https://n8n.io)** with Tailscale as a sidecar container to securely manage and access your self-hosted notes and collaboration app over a private Tailscale network. By integrating Tailscale, you can ensure that your N8N instance is only accessible to authorized devices within your Tailscale network, protecting your ideas and information from the public web.

## N8N.io

[N8N](https://n8n.io) is a flexible AI workflow automation for technical teams. Build with the precision of code or the speed of drag-n-drop. Host with on-prem control or in-the-cloud convenience. n8n gives you more freedom to implement multi-step AI agents and integrate apps than any other tool. You can plug AI into your own data and use over 500 integrations.

## Configuration Overview  

In this setup, the `tailscale-n8nce` service runs Tailscale, which manages secure networking for the N8N service. The `n8n` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This ensures that Karakeep’s web interface is only accessible through the Tailscale network (or locally, if preferred), enhancing the privacy and security of your notes and collaborative workspace.
