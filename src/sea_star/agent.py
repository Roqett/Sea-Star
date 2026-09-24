"""The agent loop: plan, call tools, answer.

Contract:
- :meth:`Agent.run` is the only entry point. It drives a bounded loop
  (``max_steps``) of model turn -> tool calls -> tool results -> model turn.
- A tool that errors is reported back to the model as an ``ERROR:`` observation
  so it can recover; the loop does not abort on tool failure.
- Exceeding ``max_steps`` raises :class:`AgentError` — SeaStar fails loud rather
  than returning a half-finished answer as if it were complete.
- Citations are extracted from the final answer's ``[[wikilinks]]``.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any

from .config import Config
from .inference import ChatResult, InferenceClient
from .tools import ToolRegistry, build_vault_tools
from .vault import Vault

CITATION_PATTERN = re.compile(r"\[\[([^\]]+)\]\]")

DEFAULT_SYSTEM_PROMPT = (
    "You are SeaStar, a private assistant that lives inside the user's Obsidian vault. "
    "You run entirely on the user's machine. Answer from the vault whenever the question "
    "concerns the user's own notes, and cite what you use with [[wikilinks]]. "
    "Prefer searching before answering. Keep answers concise and in the user's own voice."
)


class AgentError(RuntimeError):
    """Raised when the agent cannot produce a trustworthy answer."""


@dataclass(frozen=True, slots=True)
class Step:
    """One observable turn in the agent's reasoning trace."""

    kind: str
    name: str
    content: str


@dataclass(frozen=True, slots=True)
class AgentResult:
    """The answer plus the trace and citations that justify it."""

    answer: str
    steps: tuple[Step, ...] = ()
    citations: tuple[str, ...] = ()


def extract_citations(answer: str) -> tuple[str, ...]:
    seen: list[str] = []
    for match in CITATION_PATTERN.finditer(answer):
        target = match.group(1)
        if target not in seen:
            seen.append(target)
    return tuple(seen)


class Agent:
    """A bounded tool-using agent bound to one inference client and tool registry."""

    def __init__(
        self,
        client: InferenceClient,
        registry: ToolRegistry,
        *,
        max_steps: int = 8,
        temperature: float = 0.2,
        system_prompt: str = DEFAULT_SYSTEM_PROMPT,
    ) -> None:
        self._client = client
        self._registry = registry
        self._max_steps = max_steps
        self._temperature = temperature
        self._system_prompt = system_prompt

    @property
    def registry(self) -> ToolRegistry:
        return self._registry

    async def run(self, prompt: str, history: list[dict[str, Any]] | None = None) -> AgentResult:
        messages: list[dict[str, Any]] = [{"role": "system", "content": self._system_prompt}]
        if history:
            messages.extend(history)
        messages.append({"role": "user", "content": prompt})

        schemas = self._registry.schema_list()
        steps: list[Step] = []

        for _ in range(self._max_steps):
            result = await self._client.chat(
                messages,
                tools=schemas or None,
                temperature=self._temperature,
            )
            if not result.wants_tools:
                steps.append(Step(kind="answer", name="assistant", content=result.content))
                return AgentResult(
                    answer=result.content,
                    steps=tuple(steps),
                    citations=extract_citations(result.content),
                )

            messages.append(_assistant_tool_message(result))
            for call in result.tool_calls:
                steps.append(Step(kind="tool_call", name=call.name, content=call.arguments))
                try:
                    observation = await self._registry.call(call.name, call.arguments)
                except (KeyError, ValueError, RuntimeError) as error:
                    observation = f"ERROR: {error}"
                steps.append(Step(kind="observation", name=call.name, content=observation))
                messages.append(
                    {"role": "tool", "tool_call_id": call.id, "content": observation}
                )

        raise AgentError(f"Agent exceeded {self._max_steps} steps without a final answer.")


def _assistant_tool_message(result: ChatResult) -> dict[str, Any]:
    return {
        "role": "assistant",
        "content": result.content or None,
        "tool_calls": [
            {
                "id": call.id,
                "type": "function",
                "function": {"name": call.name, "arguments": call.arguments},
            }
            for call in result.tool_calls
        ],
    }


async def build_agent(config: Config) -> Agent:
    """Assemble the concrete agent: vault tools plus any bridged external MCP tools."""

    from .mcp_client import list_external_tools

    vault = Vault(config.vault_path)
    registry = ToolRegistry(build_vault_tools(vault))
    if config.servers:
        registry.extend(await list_external_tools(config.servers))
    client = InferenceClient(config.base_url, config.model, api_key=config.api_key)
    return Agent(
        client,
        registry,
        max_steps=config.max_steps,
        temperature=config.temperature,
    )