# Known Harnesses & Models — Reference List

> This is a reference, not a gate. Sea-Star must recognise anything that
> answers `/v1/models` on loopback, regardless of whether it appears here.
> This list exists to make the vocabulary and bundle-ID tables *complete by
> default*, so common tools work without the founder having to name them.

Last updated: 2026-10-15

---

## Harnesses — Local Inference Servers

| Product | Bundle ID / CLI | Default Port | Notes |
|---------|----------------|--------------|-------|
| Ollama | `com.ollama.ollama` / `ollama` | 11434 | The default for most local setups |
| LM Studio | `com.lmstudio.LMStudio` | 1234 | GUI, popular on macOS |
| MLX Server | — / `mlx_lm.server` | 8080 | Apple Silicon native |
| oMLX | `app.omlx` | 8000 | MLX wrapper with GUI |
| Unsloth Studio | `ai.unsloth.studio` | 8888 | Fine-tuning + serving |
| vLLM | — / `vllm` | 8000 | High-throughput server |
| llama.cpp | — / `llama-server` | 8080 | The original, still widely used |
| text-generation-webui | — / `server.py` | 7860 | "oobabooga", the Swiss Army knife |
| Atomic Chat | `com.atomicchat` | 1337 | macOS app, inbuilt MLX server |
| Osaurus | `com.dinoki.osaurus` | 1337 | macOS agent app |
| Open WebUI | `com.openwebui` | 3000 | Web front-end, can proxy to backends |
| Jan | `ai.jan` | 1337 | Electron app, local-first |
| GPT4All | `com.nomic.gpt4all` | 4891 | Desktop app |
| KoboldCpp | — / `koboldcpp` | 5001 | GGUF-focused server |
| Tabby | `com.tabbyml` | 8080 | Self-hosted AI coding assistant |
| LocalAI | — / `local-ai` | 8080 | Drop-in OpenAI replacement |
| llamafile | — / `llamafile` | 8080 | Single-file distributable |
| DeepSeek Harness | `com.deepseek.dsh` | — | The harness this project lives in |

## Harnesses — CLI Agent Tools

| Product | CLI Name | Notes |
|---------|----------|-------|
| OpenCode | `opencode` | Terminal agent |
| Goose | `goose` | Block open-source agent |
| Aider | `aider` | Pair programming with AI |
| Claude Code | `claude` | Anthropic's CLI agent |
| Codex CLI | `codex` | OpenAI's CLI agent |
| DeepSeek Harness | `dsh` | This project's CLI |

## Harnesses — IDE Integrations

| Product | Bundle ID | Notes |
|---------|-----------|-------|
| Cursor | `com.todesktop.230313mzl4w4u92` | AI-first editor |
| Windsurf | `com.exafunction.windsurf` | Codeium's editor |
| Trae | `com.trae.app` | ByteDance's editor |
| TraeCode | `com.trae.solo.app` | Trae's coding variant |
| TraeWork | `com.trae.solo.app` | Trae's work variant |
| Xcode | `com.apple.dt.Xcode` | Apple's IDE |
| OpenCode Desktop | `ai.opencode.desktop` | GUI for OpenCode |
| OpenCode Desktop Beta | `ai.opencode.desktop.beta` | Beta channel |
| TraeCode | `com.trae.app` | ByteDance editor |
| TraeWork | `com.trae.solo.app` | ByteDance editor |

---

## Models — Commonly Run Locally

### General Purpose

| Model | Sizes | Notes |
|-------|-------|-------|
| Llama 3.1 / 3.2 / 3.3 | 1B, 3B, 8B, 70B, 405B | Meta's flagship, the default benchmark |
| Llama 4 | Scout (17B), Maverick (17B×128E) | MoE architecture |
| Qwen 2.5 / 3 | 0.5B–110B, 235B-A22B (MoE) | Alibaba, strong at coding and math |
| Mistral 7B / Nemo 12B / Large | 7B, 12B, 123B | French, efficient |
| Mixtral 8×7B / 8×22B | MoE | Sparse mixture of experts |
| Phi 3 / 4 | Mini (3.8B), Medium (14B) | Microsoft, small but capable |
| Gemma 2 / 3 | 2B, 9B, 27B | Google, open weights |
| DeepSeek V3 / R1 | 671B (MoE) | Strong reasoning, large |
| Yi 1.5 | 6B, 9B, 34B | 01.AI, strong multilingual |
| Command R / R+ | 35B, 104B | Cohere, RAG-optimised |
| Solar 10.7B | 10.7B | Upstage, depth-upscaling |
| Jamba 1.5 | Mini (52B), Large (398B) | AI21, hybrid Mamba/Transformer |
| Granite 3 | 1B–8B | IBM, enterprise-focused |

### Coding

| Model | Sizes | Notes |
|-------|-------|-------|
| CodeLlama | 7B, 13B, 34B, 70B | Meta's code-specialised Llama |
| DeepSeek Coder V2 | 16B, 236B (MoE) | Strong coding benchmark scores |
| StarCoder 2 | 3B, 7B, 15B | BigCode, permissive licence |
| Qwen 2.5-Coder | 0.5B–32B | Code-specialised Qwen |
| Codestral | 22B | Mistral's coding model |
| Magicoder | 7B | Open-source, permissive |

### Embedding

| Model | Dimensions | Notes |
|-------|-----------|-------|
| nomic-embed-text | 768 | Popular with Ollama users |
| mxbai-embed-large | 1024 | Mixedbread AI |
| all-MiniLM-L6-v2 | 384 | Sentence Transformers classic |
| Qwen 3 Embedding | Various | Multilingual |
| bge-large / bge-m3 | 1024 | BAAI, strong multilingual |

### Vision / Multimodal

| Model | Sizes | Notes |
|-------|-------|-------|
| Llama 3.2 Vision | 11B, 90B | Meta's multimodal |
| Qwen 2.5-VL | 3B, 7B, 72B | Strong vision-language |
| LLaVA 1.6 | 7B, 13B, 34B | Open-source vision |
| InternVL 2.5 | 1B–78B | Shanghai AI Lab |
| Molmo | 7B, 72B | Allen AI, strong OCR |

---

## Vocabulary Words

These are the words `recon.py` scans for in process names/paths. Add to this
list when a new runtime family emerges, not when a new product appears — the
list is of *families*, not products.

```
llama, ggml, gguf, mlx, ollama, vllm, whisper, transformers,
text-generation, inference-server, model-server
```

Suggested additions to consider:
- `unsloth` — Unsloth Studio's server process
- `kobold` — KoboldCpp
- `tabby` — Tabby server
- `jan` — Jan Electron app
- `gpt4all` — GPT4All
- `localai` — LocalAI
- `llamafile` — llamafile
- `deepseek` — DeepSeek server
- `qwen` — Qwen server
- `mistral` — Mistral server
- `phi` — Microsoft Phi server
- `gemma` — Google Gemma server
