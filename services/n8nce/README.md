# n8n with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [n8n](https://n8n.io/) with **Tailscale** as a secure sidecar container, allowing you to access the n8n workflow automation UI only through your private Tailnet network.

---

## n8n

[n8n](https://n8n.io/) is an extendable workflow automation tool that enables integration and automation between different applications, APIs, and services.  
It provides a visual editor to build powerful workflows and can run locally, self-hosted, or in the cloud.

## ollama

Ollama is a lightweight local LLM runtime that lets you run, manage, and interact with AI models directly on your machine.

| Model                        | Approx. Size / Parameters                                | Description                                                                                                                                                          |
| ---------------------------- | -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **deepseek-coder:1.3b-base** | ~1.3 B parameters. ([Ollama][1])                         | Code-specialised model trained from scratch on ~2 trillion tokens (≈ 87% code / 13% natural language) for code generation/completion. ([Hugging Face][2])            |
| **phi3:mini**                | ~3.8 B parameters. ([Ollama][3])                         | Lightweight variant of the Phi-3 family (by Microsoft) designed for high-quality reasoning/instruction tasks with smaller footprint. ([Analytics Vidhya][4])         |
| **codellama:7b**             | ~7 B parameters. ([Ollama][5])                           | Code-generation model from Meta Platforms optimized for code tasks (completion, tests, reviews). ([Amazon Web Services, Inc.][6])                                    |
| **codeqwen:1.5b**            | ~1.5 B parameters (for Qwen2.5/Coder series) ([Qwen][7]) | Code-oriented model within the Qwen2.5 family (by Alibaba Cloud) covering code generation and reasoning for code domains.                                            |
| **starcoder2:3b**            | ~3 B parameters. ([Dataloop][8])                         | Open-source code LLM by the BigCode community trained on many languages; suited for code generation. ([Hugging Face][9])                                             |
| **llama3.2:3b**              | ~3 B parameters? *(Exact figure not found)*              | General-purpose model in the Llama/3-series family (by Meta Platforms). Good for “general purpose” tasks. *(You may need to check the exact size for this version.)* |
| **mistral:7b**               | ~7 B parameters. *(Exact details not captured here)*     | General-purpose open model by Mistral AI focused on high performance in large-model tasks. *(Need official spec citation.)*                                          |
| **gemma2:2b**                | ~2 B parameters. ([apxml.com][10])                       | Model family by Google DeepMind / Google with a 2 B-param variant; emphasises efficient architecture and competitive performance. ([Ollama][11])                     |
| **qwen2.5:1.5b**             | ~1.5 B parameters, file size ~986 MB. ([Ollama][12])     | LLM by Alibaba’s Qwen 2.5 series, supports long contexts (128K tokens) and multilingual/coding capabilities. ([Qwen][13])                                            |

[1]: https://ollama.com/library/deepseek-coder%3A1.3b-base?utm_source=chatgpt.com "deepseek-coder:1.3b-base - Ollama"
[2]: https://huggingface.co/deepseek-ai/deepseek-coder-1.3b-base?utm_source=chatgpt.com "deepseek-ai/deepseek-coder-1.3b-base - Hugging Face"
[3]: https://ollama.com/library/phi3?utm_source=chatgpt.com "phi3 - Ollama"
[4]: https://www.analyticsvidhya.com/blog/2024/04/microsoft-phi-3/?utm_source=chatgpt.com "Microsoft Phi 3 Mini: Smallest AI Model - Analytics Vidhya"
[5]: https://ollama.com/library/codellama?utm_source=chatgpt.com "codellama"
[6]: https://aws.amazon.com/blogs/machine-learning/code-llama-code-generation-models-from-meta-are-now-available-via-amazon-sagemaker-jumpstart/?utm_source=chatgpt.com "Code Llama code generation models from Meta are now ..."
[7]: https://qwenlm.github.io/blog/qwen2.5-coder-family/?utm_source=chatgpt.com "Qwen2.5-Coder Series: Powerful, Diverse, Practical. | Qwen"
[8]: https://dataloop.ai/library/model/bigcode_starcoder2-3b/?utm_source=chatgpt.com "Starcoder2 3b · Models - Dataloop"
[9]: https://huggingface.co/docs/transformers/en/model_doc/starcoder2?utm_source=chatgpt.com "Starcoder2"
[10]: https://apxml.com/models/gemma-2-2b?utm_source=chatgpt.com "Gemma 2 2B: Specifications and GPU VRAM Requirements"
[11]: https://ollama.com/library/gemma2%3A2b?utm_source=chatgpt.com "gemma2:2b"
[12]: https://ollama.com/library/qwen2.5%3A1.5b?utm_source=chatgpt.com "qwen2.5:1.5b - Ollama"
[13]: https://qwenlm.github.io/blog/qwen2.5-llm/?utm_source=chatgpt.com "Qwen2.5-LLM: Extending the boundary of LLMs | Qwen"


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