# Open WebUI with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Open WebUI](https://openwebui.com/) with Tailscale as a sidecar container to keep the app reachable over your Tailnet.

## Open WebUI

[Open WebUI](https://openwebui.com/) is a feature-rich, self-hosted AI platform that provides a ChatGPT-style interface for local and cloud-based AI models. It supports Ollama and any OpenAI-compatible API. Pairing it with Tailscale means your private AI interface is securely accessible from any of your devices without exposing it to the public internet.

## Configuration Overview

In this setup, the `tailscale-open-webui` service runs Tailscale, which manages secure networking for Open WebUI. The `open-webui` service utilizes the Tailscale network stack via Docker's `network_mode: service:` configuration. This keeps the app Tailnet-only unless you intentionally expose ports.

## What to document for users

- **Prerequisites**: Docker and Docker Compose installed. No special group membership, GPU, or devices required for CPU-only inference. A Tailscale account with an auth key from <https://tailscale.com/admin/authkeys>.
- **Volumes**: Pre-create `./open-webui-data` before deploying to avoid Docker creating a root-owned directory: `mkdir -p ./open-webui-data ./config ./ts/state`
- **MagicDNS/Serve**: Enable MagicDNS and HTTPS in your Tailscale admin console before deploying. The serve config proxies to port `8080` — this is hardcoded in the `configs` block and does not consume `.env` values. Uncomment `TS_ACCEPT_DNS=true` in `compose.yaml` if DNS resolution issues arise.
- **Ollama**: Set `OLLAMA_BASE_URL` in `.env` to point at your Ollama instance. Options:
  - Same Docker host: `http://host.docker.internal:11434`
  - LAN machine: `http://<local-ip>:11434` (use the private IP of the machine running Ollama)
  - Another Tailnet device: `http://100.x.x.x:11434`
  - Leave blank to keep the OpenAI-compatible connection below (OrcaRouter by default).
- **OrcaRouter (default OpenAI-compatible connection)**: The stack pre-wires Open WebUI's OpenAI connection to [OrcaRouter](https://www.orcarouter.ai) (`https://api.orcarouter.ai/v1`). OrcaRouter is an OpenAI-compatible AI gateway — like OpenRouter, it exposes a provider/model namespace across many models, and it also combines adaptive routing, automatic failover, zero-markup inference, observability, guardrails, and agent-tool governance behind the same endpoint. To enable it, set `OPENAI_API_KEY` in `.env` to your OrcaRouter key (generate one at <https://www.orcarouter.ai>). It also runs gateway-level, zero-trust security for AI agents on the same endpoint — screening every prompt and response and governing every tool call on a default-deny basis, with no application code changes.
  - Switch to another OpenAI-compatible provider (e.g. OpenAI) by changing `OPENAI_API_BASE_URL` in `.env`, or add more connections in the UI via **Settings → Connections**.
- **Ports**: The `0.0.0.0:${SERVICEPORT}:${SERVICEPORT}` mapping is commented out by default. Uncomment only if LAN access is required alongside Tailnet access.
- **Gotchas**:
  - Create your admin account immediately after first launch — Open WebUI is open to registration until the first user is created.
  - Open WebUI requires WebSocket support — ensure nothing in your network path blocks WebSocket connections.
  - After adding new models to Ollama, refresh the model list in Open WebUI via **Settings → Connections**.

## Files to check

Please check the following contents for validity as some variables need to be defined upfront.

- `.env` // Main variables: `TS_AUTHKEY`, `SERVICE`, `IMAGE_URL`, `OLLAMA_BASE_URL`, `OPENAI_API_KEY`, `WEBUI_SECRET_KEY`

## Resources

- [Open WebUI Documentation](https://docs.openwebui.com/)
- [Open WebUI GitHub](https://github.com/open-webui/open-webui)
- [Tailscale Serve docs](https://tailscale.com/kb/1242/tailscale-serve)
- [Tailscale Docker guide](https://tailscale.com/blog/docker-tailscale-guide)
