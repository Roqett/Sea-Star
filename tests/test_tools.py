"""Tool registry and built-in vault tools."""

from __future__ import annotations

import pytest

from sea_star.tools import ToolRegistry, build_vault_tools
from sea_star.vault import Vault


@pytest.fixture()
def registry(tmp_path):
    (tmp_path / "wine.md").write_text("Malolactic fermentation notes.\n#wine\n", encoding="utf-8")
    return ToolRegistry(build_vault_tools(Vault(tmp_path)))


def test_builtin_tools_are_registered(registry):
    assert set(registry.names()) == {"vault_search", "vault_read", "vault_list", "vault_append"}


def test_schema_list_is_openai_shaped(registry):
    schema = next(s for s in registry.schema_list() if s["function"]["name"] == "vault_search")
    assert schema["type"] == "function"
    assert "query" in schema["function"]["parameters"]["properties"]


async def test_search_call_returns_citations(registry):
    output = await registry.call("vault_search", '{"query": "fermentation"}')
    assert "[[wine]]" in output


async def test_append_then_read(registry):
    await registry.call("vault_append", '{"path": "log.md", "content": "day one"}')
    assert "day one" in await registry.call("vault_read", '{"path": "log.md"}')


async def test_unknown_tool_raises(registry):
    with pytest.raises(KeyError):
        await registry.call("nope", "{}")


async def test_invalid_json_arguments_raise(registry):
    with pytest.raises(ValueError):
        await registry.call("vault_search", "{not json")


def test_duplicate_tool_names_rejected(registry):
    existing = next(t for t in registry._tools.values())
    with pytest.raises(ValueError):
        registry.register(existing)