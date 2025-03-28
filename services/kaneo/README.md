# Kaneo with Tailscale Sidecar Configuration  

This Docker Compose configuration sets up **[Kaneo](https://github.com/usekaneo/kaneo)** with Tailscale as a sidecar container to securely manage and access your self-hosted project management platform over a private Tailscale network. By integrating Tailscale, you ensure that your Kaneo instance is only accessible to authorized devices within your Tailscale network, keeping your tasks, projects, and team discussions private.

## Kaneo  

[Kaneo](https://github.com/usekaneo/kaneo) is an **open-source, self-hosted project management platform** focused on simplicity, clean UI, and efficient workflows. Designed as an alternative to tools like Trello or Linear, Kaneo offers a modern and distraction-free environment to manage tasks, organize projects, and collaborate with your team. You can self-host and fully customize the platform to match your workflow—no vendor lock-in, no subscriptions.

## Key Features  

- **Project & Task Boards** – Kanban-style boards for managing tasks and workflows.  
- **Clean & Fast UI** – Minimalist design focused on usability and speed.  
- **Self-Hosted & Customizable** – Deploy on your own infrastructure and modify freely.  
- **Privacy-First** – No tracking, no external dependencies.  
- **Secure Access with Tailscale** – Limit access to authorized devices in your private network.  

## Configuration Overview  

In this setup, the `tailscale-kaneo` service runs Tailscale, which manages secure networking for the Kaneo service. The `kaneo` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This ensures that Kaneo’s web interface is only accessible through the Tailscale network (or locally, if preferred), adding a strong layer of privacy and security to your self-hosted project management platform.
