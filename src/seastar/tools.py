"""Tool registry and SeaStar's built-in vault tools.

Contract:
- A :class:`Tool` bundles the JSON schema a model sees with the async handler
  SeaStar actually runs. Handlers return plain text; they never raise for a
  user-level problem (an empty search is text, not an exception) but do raise
  for programmer errors.
- :class:`ToolRegistry` is the single dispatch point for every tool call, from
  built-in vault tools to bridged external MCP tools.
"""

from __future__ import annotations

import json
from collections.abc import Awaitable, Callable, Iterable
from dataclasses import dataclass
from typing import Any

from .vault import Vault, VaultError

ToolHandler = Callable[..., Awaitable[str]]


@dataclass(frozen=True, slots=True)
class Tool:
    """One callable capability exposed to the model."""

    name: str
    description: str
    parameters: dict[str, Any]
    handler: ToolHandler

    def schema(self) -> dict[str, Any]:
        return {
            "type": "function",
            "function": {
                "name": self.name,
                "description": self.description,
                "parameters": self.parameters,
            },
        }


class ToolRegistry:
    """Ordered, name-keyed collection of tools with a single async dispatcher."""

    def __init__(self, tools: Iterable[Tool] = ()) -> None:
        self._tools: dict[str, Tool] = {}
        for tool in tools:
            self.register(tool)

    def register(self, tool: Tool) -> None:
        if tool.name in self._tools:
            raise ValueError(f"Duplicate tool name: {tool.name}")
        self._tools[tool.name] = tool

    def extend(self, tools: Iterable[Tool]) -> None:
        for tool in tools:
            self.register(tool)

    def __contains__(self, name: object) -> bool:
        return name in self._tools

    def names(self) -> tuple[str, ...]:
        return tuple(self._tools)

    def schema_list(self) -> list[dict[str, Any]]:
        return [tool.schema() for tool in self._tools.values()]

    async def call(self, name: str, arguments: str) -> str:
        """Dispatch one tool call, parsing the model's raw JSON argument string."""

        tool = self._tools.get(name)
        if tool is None:
            raise KeyError(f"Unknown tool: {name}")
        try:
            kwargs = json.loads(arguments) if arguments.strip() else {}
        except json.JSONDecodeError as error:
            raise ValueError(f"Tool {name} received invalid JSON arguments: {error}") from error
        if not isinstance(kwargs, dict):
            raise TypeError(f"Tool {name} arguments must be a JSON object.")
        return await tool.handler(**kwargs)


def build_vault_tools(vault: Vault) -> tuple[Tool, ...]:
    """The four built-in tools that give any model memory of the vault."""

    async def vault_search(query: str, limit: int = 10) -> str:
        hits = vault.search(query, limit=limit)
        if not hits:
            return f"No notes matched {query!r}."
        lines = [f"{hit.note.citation()} (score {hit.score})" for hit in hits]
        return "Matches:\n" + "\n".join(lines)

    async def vault_read(path: str) -> str:
        try:
            return vault.read(path)
        except VaultError as error:
            return f"Could not read {path!r}: {error}"

    async def vault_list(folder: str = "") -> str:
        notes = vault.list_notes(folder or None)
        if not notes:
            return "No notes found."
        return "\n".join(f"{note.citation()} ({note.size} bytes)" for note in notes)

    async def vault_append(path: str, content: str) -> str:
        try:
            written = vault.append(path, content)
        except VaultError as error:
            return f"Could not write {path!r}: {error}"
        return f"Appended to {vault.relative_to_root(written)}"

    return (
        Tool(
            name="vault_search",
            description="Search the Obsidian vault for notes matching a query. Use this first.",
            parameters={
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Keywords to search for."},
                    "limit": {"type": "integer", "description": "Maximum notes to return."},
                },
                "required": ["query"],
            },
            handler=vault_search,
        ),
        Tool(
            name="vault_read",
            description="Read the full contents of one vault note by its relative path.",
            parameters={
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Vault-relative note path."},
                },
                "required": ["path"],
            },
            handler=vault_read,
        ),
        Tool(
            name="vault_list",
            description="List notes, optionally within one folder, with their paths and sizes.",
            parameters={
                "type": "object",
                "properties": {
                    "folder": {"type": "string", "description": "Optional folder prefix."},
                },
            },
            handler=vault_list,
        ),
        Tool(
            name="vault_append",
            description="Append text to a note, creating it if it does not exist.",
            parameters={
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Vault-relative note path."},
                    "content": {"type": "string", "description": "Markdown to append."},
                },
                "required": ["path", "content"],
            },
            handler=vault_append,
        ),
    )