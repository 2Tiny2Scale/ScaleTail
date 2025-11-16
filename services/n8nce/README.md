# n8n with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [n8n](https://n8n.io/) with **Tailscale** as a secure sidecar container, allowing you to access the n8n workflow automation UI only through your private Tailnet network.

---

## n8n

[n8n](https://n8n.io/) is an extendable workflow automation tool that enables integration and automation between different applications, APIs, and services. It provides a visual editor to build powerful workflows and can run locally, self-hosted, or in the cloud.

## ollama

Ollama is a lightweight local LLM runtime that lets you run, manage, and interact with AI models directly on your machine.

| Model                        | Approx. Size / Parameters                                | Description                                                                                                                                                          |
| ---------------------------- | -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **deepseek-coder:1.3b-base** | ~1.3 B parameters. | Code-specialised model trained from scratch on ~2 trillion tokens (≈ 87% code / 13% natural language) for code generation/completion.|
| **phi3:mini**                | ~3.8 B parameters. | Lightweight variant of the Phi-3 family (by Microsoft) designed for high-quality reasoning/instruction tasks with smaller footprint.|
| **codellama:7b**             | ~7 B parameters. | Code-generation model from Meta Platforms optimized for code tasks (completion, tests, reviews).|
| **codeqwen:1.5b**            | ~1.5 B parameters | Code-oriented model within the Qwen2.5 family (by Alibaba Cloud) covering code generation and reasoning for code domains.|
| **starcoder2:3b**            | ~3 B parameters.  | Open-source code LLM by the BigCode community trained on many languages; suited for code generation.|
| **llama3.2:3b**              | ~3 B parameters?  | General-purpose model in the Llama/3-series family (by Meta Platforms). Good for “general purpose” tasks. |
| **mistral:7b**               | ~7 B parameters.  | General-purpose open model by Mistral AI focused on high performance in large-model tasks.|
| **gemma2:2b**                | ~2 B parameters.  | Model family by Google DeepMind / Google with a 2 B-param variant; emphasises efficient architecture and competitive performance.|
| **qwen2.5:1.5b**             | ~1.5 B parameters, file size ~986 MB. | LLM by Alibaba’s Qwen 2.5 series, supports long contexts (128K tokens) and multilingual/coding capabilities.|


---

## Configuration Overview

In this setup:

- The `tailscale` container manages private networking using your Tailscale Tailnet.
- The `n8n` container uses Docker’s `network_mode: service:tailscale` to route all its traffic securely through Tailscale.
- The setup ensures that n8n’s UI is **not exposed to the public internet**, but is accessible over your private Tailscale network.
- The configuration includes health checks and persistent storage.

---

## Files to Check

Ensure the following files are correctly configured:

- `.env` — contains environment variables and authentication keys.
- `./config/serve.json` — defines how Tailscale serves the n8n web interface securely on port 443.

---

## Running the Stack

```bash
mkdir -p ./n8n_storage/
docker compose up -d
```

[![asciicast](https://asciinema.org/a/0sKM3JBOoYeJaVztaHKqgIwXw.svg)](https://asciinema.org/a/0sKM3JBOoYeJaVztaHKqgIwXw)

## Troubleshooting

To view logs:
```bash
docker compose logs -f n8n
docker compose logs -f tailscale
docker compose logs -f ollama
```