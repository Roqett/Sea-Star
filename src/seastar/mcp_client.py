"""Bridge external MCP servers into SeaStar's tool registry.

Contract:
- Each configured server is spawned over stdio, its tools are listed, and every
  tool is re-exposed under a namespaced name (``<server>__<tool>``) so two
  servers cannot collide.
- Sessions are short-lived: SeaStar opens one to discover tools and one per call.
  This is deliberately simple for 0.1; a pooled session can replace it later
  without changing the tool surface.
- A server that fails to start raises :class:`MCPClientError` — SeaStar does not
  pretend a configured capability exists when it does not.
"""

from __future__ import annotations

import os
from typing import Any

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

from .config import MCPServerSpec
from .tools import Tool

TOOL_NAME_SEPARATOR = "__"


class MCPClientError(RuntimeError):
    """Raised when an external MCP server cannot be reached or used."""


def _params(spec: MCPServerSpec) -> StdioServerParameters:
    env = {**os.environ, **spec.env_dict()} if spec.env else None
    return StdioServerParameters(command=spec.command, args=list(spec.args), env=env)


def _render(result: Any) -> str:
    blocks = getattr(result, "content", None) or []
    parts: list[str] = []
    for block in blocks:
        text = getattr(block, "text", None)
        parts.append(text if text is not None else f"[{getattr(block, 'type', 'content')}]")
    return "\n".join(parts) if parts else "(no content)"


async def list_external_tools(specs: tuple[MCPServerSpec, ...]) -> tuple[Tool, ...]:
    """Discover tools from every configured server and wrap them as SeaStar tools."""

    tools: list[Tool] = []
    for spec in specs:
        try:
            async with (
                stdio_client(_params(spec)) as (read, write),
                ClientSession(read, write) as session,
            ):
                await session.initialize()
                listed = await session.list_tools()
        except Exception as error:
            raise MCPClientError(f"MCP server {spec.name!r} failed: {error}") from error

        for remote in listed.tools:
            tools.append(
                Tool(
                    name=f"{spec.name}{TOOL_NAME_SEPARATOR}{remote.name}",
                    description=remote.description or f"{spec.name} tool {remote.name}",
                    parameters=remote.inputSchema or {"type": "object", "properties": {}},
                    handler=_make_handler(spec, remote.name),
                )
            )
    return tuple(tools)


def _make_handler(spec: MCPServerSpec, remote_name: str):
    async def handler(**kwargs: Any) -> str:
        try:
            async with (
                stdio_client(_params(spec)) as (read, write),
                ClientSession(read, write) as session,
            ):
                await session.initialize()
                result = await session.call_tool(remote_name, arguments=kwargs)
        except Exception as error:
            raise MCPClientError(f"{spec.name}::{remote_name} failed: {error}") from error
        return _render(result)

    return handler