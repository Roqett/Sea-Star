# Changelog

All notable changes to SeaStar are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Runtime-agnostic inference** (`inference.py`): talks the OpenAI-compatible
  chat-completions protocol over raw `httpx`, so Ollama, LM Studio, llama.cpp,
  MLX, vLLM and Unsloth Studio all work without a vendor lock-in.
- **Zero-config autodetection** (`config.py`): probes the six common local ports
  and adopts the first runtime that answers; fails loud when none do.
- **Obsidian vault memory** (`vault.py`): scan, ranked search, read, write and
  append, with traversal-safe paths and `[[wikilink]]` citations.
- **Bounded agent loop** (`agent.py`): model turn → tool calls → observations →
  cited answer, capped by `max_steps`.
- **MCP server** (`mcp_server.py`): exposes `ask_seastar`, `vault_search`,
  `vault_read` and `vault_list` over stdio for Claude Desktop, Cursor, Trae, etc.
- **MCP client** (`mcp_client.py`): bridges external MCP servers (e.g. Obsidian
  ones) into SeaStar's own tool registry under namespaced names.
- **CLI** (`cli.py`): `seastar init | doctor | ask | serve | version`.
- **Factory protocol** (`AGENTS.md`): Tier 1/Tier 2 tripwires and core invariants.
- Test suite covering the vault, config resolution, tool registry, agent loop and
  MCP server surface.

### Fixed

- Corrected `agent.build_agent` to import `list_external_tools` (it previously
  referenced a non-existent `load_external_tools`, breaking every config that
  declared a bridged MCP server).

[Unreleased]: https://github.com/Roqett/theSeaStar/commits/main