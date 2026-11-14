"""The MCP server surface exposes the expected tools."""

from __future__ import annotations

from sea_star.agent import Agent
from sea_star.mcp_server import create_server
from sea_star.tools import ToolRegistry
from sea_star.vault import Vault


class _FakeClient:
    async def chat(self, messages, *, tools=None, temperature=0.2):  # pragma: no cover - unused
        raise AssertionError("the server should not call the model during discovery")


def _server(tmp_path):
    (tmp_path / "note.md").write_text("hello", encoding="utf-8")
    config = type(
        "Cfg",
        (),
        {"vault_path": tmp_path},
    )()
    agent = Agent(_FakeClient(), ToolRegistry())
    return create_server(config, agent)


async def test_server_exposes_expected_tools(tmp_path):
    server = _server(tmp_path)
    tools = await server.list_tools()
    assert {tool.name for tool in tools} == {
        "ask_seastar",
        "machine_report",
        "vault_search",
        "vault_read",
        "vault_list",
    }


async def test_machine_report_answers_a_host(tmp_path):
    """The symmetry clause: what the cockpit can see, a host can ask for.

    A host attached to Sea-Star has no way to read this machine's sockets, so
    without this tool it would have to guess where models come from. The answer
    names the app an inbuilt server belongs to, because that is the fact that
    decides whether the endpoint is still there tomorrow.
    """

    server = _server(tmp_path)
    result = await server.call_tool("machine_report", {})
    text = result if isinstance(result, str) else str(result)

    assert "Model servers on this machine" in text or "No local model servers" in text


def test_vault_is_reachable_from_config(tmp_path):
    assert Vault(tmp_path).scan() == ()