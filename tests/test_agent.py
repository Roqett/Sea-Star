"""The agent loop, driven by a scripted fake inference client (no network)."""

from __future__ import annotations

import pytest

from seastar.agent import Agent, AgentError, extract_citations
from seastar.inference import ChatResult, ToolCall
from seastar.tools import Tool, ToolRegistry


class FakeClient:
    """Stands in for InferenceClient; returns canned turns in order."""

    def __init__(self, turns):
        self._turns = list(turns)
        self.seen_messages = []

    async def chat(self, messages, *, tools=None, temperature=0.2):
        self.seen_messages.append(messages)
        if not self._turns:
            raise AssertionError("FakeClient ran out of scripted turns")
        return self._turns.pop(0)


def _lookup_tool(output: str = "found it") -> Tool:
    async def handler(query: str) -> str:
        return f"{output}: {query}"

    return Tool(
        name="lookup",
        description="test",
        parameters={"type": "object", "properties": {"query": {"type": "string"}}, "required": ["query"]},
        handler=handler,
    )


async def test_agent_resolves_tool_calls_then_answers():
    client = FakeClient(
        [
            ChatResult(content="", tool_calls=(ToolCall(id="1", name="lookup", arguments='{"query": "x"}'),)),
            ChatResult(content="Here it is. See [[note]]"),
        ]
    )
    agent = Agent(client, ToolRegistry([_lookup_tool()]), max_steps=4)
    result = await agent.run("what about x?")
    assert result.answer == "Here it is. See [[note]]"
    assert result.citations == ("note",)
    assert [step.kind for step in result.steps] == ["tool_call", "observation", "answer"]


async def test_tool_errors_are_reported_not_raised():
    client = FakeClient(
        [
            ChatResult(content="", tool_calls=(ToolCall(id="1", name="missing", arguments="{}"),)),
            ChatResult(content="Recovered."),
        ]
    )
    agent = Agent(client, ToolRegistry([_lookup_tool()]), max_steps=4)
    result = await agent.run("go")
    observation = next(step for step in result.steps if step.kind == "observation")
    assert observation.content.startswith("ERROR:")


async def test_agent_fails_loud_on_step_limit():
    endless = ChatResult(content="", tool_calls=(ToolCall(id="1", name="lookup", arguments='{"query": "x"}'),))
    client = FakeClient([endless, endless, endless, endless])
    agent = Agent(client, ToolRegistry([_lookup_tool()]), max_steps=2)
    with pytest.raises(AgentError):
        await agent.run("loop forever")


def test_extract_citations_dedupes_in_order():
    assert extract_citations("a [[One]] b [[Two]] c [[One]]") == ("One", "Two")