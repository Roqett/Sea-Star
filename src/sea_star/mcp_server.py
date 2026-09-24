"""The MCP server face: what a host (Claude Desktop, Cursor, Trae, ...) sees.

Contract:
- SeaStar presents itself to an MCP host as a small tool surface. The headline
  tool is ``ask_seastar``, which runs the full local agent loop and returns a
  cited answer.
- Direct vault tools (``vault_search``, ``vault_read``, ``vault_list``) are also
  exposed so a host can inspect notes without spending a model round-trip.
- The server never exposes an inference endpoint, a key, or an outbound request;
  it is a front door onto local capability only.
"""

from __future__ import annotations

from mcp.server import MCPServer

from .agent import Agent
from .config import Config
from .vault import Vault, VaultError

INSTRUCTIONS = (
    "SeaStar is a private, local-first agent with memory of an Obsidian vault. "
    "Use `ask_seastar` for questions that need reasoning across notes; use the "
    "`vault_*` tools for direct lookups. Everything runs on this machine."
)


def create_server(config: Config, agent: Agent) -> MCPServer:
    """Build the MCPServer surface bound to a live agent and vault."""

    vault = Vault(config.vault_path)
    server = MCPServer("SeaStar", instructions=INSTRUCTIONS)

    @server.tool()
    async def ask_seastar(question: str) -> str:
        """Ask SeaStar a question; it searches the vault and answers with citations."""

        result = await agent.run(question)
        if not result.citations:
            return result.answer
        sources = ", ".join(f"[[{citation}]]" for citation in result.citations)
        return f"{result.answer}\n\nSources: {sources}"

    @server.tool()
    async def vault_search(query: str, limit: int = 10) -> str:
        """Search the Obsidian vault for notes matching a query."""

        hits = vault.search(query, limit=limit)
        if not hits:
            return f"No notes matched {query!r}."
        return "\n".join(f"{hit.note.citation()} (score {hit.score})" for hit in hits)

    @server.tool()
    async def vault_read(path: str) -> str:
        """Read one vault note by its vault-relative path."""

        try:
            return vault.read(path)
        except VaultError as error:
            return f"Could not read {path!r}: {error}"

    @server.tool()
    async def vault_list(folder: str = "") -> str:
        """List notes, optionally within a folder, with paths and sizes."""

        notes = vault.list_notes(folder or None)
        if not notes:
            return "No notes found."
        return "\n".join(f"{note.citation()} ({note.size} bytes)" for note in notes)

    return server