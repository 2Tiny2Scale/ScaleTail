# Mattermost with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Mattermost](https://mattermost.com/platform-overview/) with Tailscale as a sidecar container to securely manage and access your clipboard history over a private Tailscale network. By integrating Tailscale, you can ensure that your Mattermost instance remains private and accessible only to authorized devices on your Tailscale network.

## Mattermost

[Mattermost](https://mattermost.com/platform-overview/) is an open-source, self-hosted collaboration platform for secure team communication and workflow automation, functioning as a secure alternative to Slack. It provides tools for chat, file sharing, and integrations, with an emphasis on data control and security for enterprise use, especially in high-stakes sectors like defense and critical infrastructure. The platform is designed for flexibility and extensibility, allowing for deep customization and integration with other tools and processes to manage complex workflows.

## Key Features

- **Secure Messaging**: Offers public and private channels, direct messaging, and secure file sharing within teams and organizations.
- **Workflow Automation**: Includes features like Playbooks to streamline and automate complex processes and tasks.
- **Self-Hosting & Data Control**: Built to be self-hosted, giving IT administrators full control over data, security, and the platform's infrastructure.
- **Open-Source & Open Core**: Features an open-source core with an open-source edition and commercial, subscription-based editions that add advanced capabilities.
- **Extensive Integrations**: Designed for seamless integration with development tools and other enterprise software, such as GitLab.
- **Multi-Platform Support**: Available as web, desktop, and mobile applications for iOS, Android, Windows, and macOS.

## Configuration Overview

In this setup, the `tailscale-Mattermost` service runs Tailscale, which manages secure networking for the Mattermost service. The `Mattermost` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This ensures that Mattermost’s web interface and functionality are only accessible through the Tailscale network (or locally, if preferred), providing enhanced privacy and security for managing your clipboard history.
