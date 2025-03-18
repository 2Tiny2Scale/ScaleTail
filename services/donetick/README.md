# Donetick with Tailscale Sidecar Configuration  

This Docker Compose configuration sets up **[Donetick](https://github.com/donetick/donetick)** with Tailscale as a sidecar container to securely manage and access your self-hosted task management system over a private Tailscale network. By integrating Tailscale, you can ensure that your Donetick instance remains private and accessible only to authorized devices within your Tailscale network.

## Donetick  

[Donetick](https://github.com/donetick/donetick) is a **self-hosted task and checklist manager** designed for simplicity and efficiency. It helps users stay organized with structured to-do lists and task tracking while ensuring full control over their data. With Donetick, you can create tasks, set deadlines, and track progress without relying on third-party services. By integrating Tailscale, you can further secure your Donetick instance by restricting access to only authorized devices within your private network.

## Key Features  

- **Task & Checklist Management** – Organize and track tasks efficiently.  
- **Collaborative Workflows** – Share tasks and checklists with team members.  
- **Self-Hosted Privacy** – Keep full control over your task management data.  
- **Minimalist & Lightweight** – A simple, distraction-free interface for productivity.  
- **Secure Access with Tailscale** – Restrict access to only authorized devices within your private network.  

## Configuration Overview  

In this setup, the `tailscale-donetick` service runs Tailscale, which manages secure networking for the Donetick service. The `donetick` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This ensures that Donetick’s web interface is only accessible through the Tailscale network (or locally, if preferred), adding an extra layer of security and privacy for managing tasks and checklists.  
