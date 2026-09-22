"""Runtime-agnostic inference adapter.

Contract:
- Every model call in SeaStar funnels through :class:`InferenceClient`. No other
  module opens a connection to a model endpoint.
- The client speaks the OpenAI chat-completions protocol, which Ollama, LM Studio,
  llama.cpp, MLX, vLLM and Unsloth Studio all expose over a local HTTP port.
- A non-2xx response is never swallowed: it raises :class:`InferenceError` with
  the upstream status and a bounded body excerpt.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import httpx

DEFAULT_TIMEOUT_SECONDS = 120.0
MODEL_LIST_TIMEOUT_SECONDS = 5.0
BODY_EXCERPT_CHARS = 300


class InferenceError(RuntimeError):
    """Raised when the inference endpoint errors or returns an unusable payload."""


@dataclass(frozen=True, slots=True)
class ToolCall:
    """A single tool invocation requested by the model."""

    id: str
    name: str
    arguments: str


@dataclass(frozen=True, slots=True)
class ChatResult:
    """One assistant turn: prose and/or requested tool calls."""

    content: str
    tool_calls: tuple[ToolCall, ...] = ()
    finish_reason: str | None = None

    @property
    def wants_tools(self) -> bool:
        return bool(self.tool_calls)


class InferenceClient:
    """Thin, explicit OpenAI-compatible client bound to one endpoint and model."""

    def __init__(
        self,
        base_url: str,
        model: str,
        *,
        api_key: str = "seastar-local",
        timeout: float = DEFAULT_TIMEOUT_SECONDS,
    ) -> None:
        self._base = base_url.rstrip("/")
        self._model = model
        self._api_key = api_key
        self._timeout = timeout

    @property
    def base_url(self) -> str:
        return self._base

    @property
    def model(self) -> str:
        return self._model

    def _headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self._api_key}", "Content-Type": "application/json"}

    async def list_models(self) -> list[str]:
        async with httpx.AsyncClient(timeout=MODEL_LIST_TIMEOUT_SECONDS) as client:
            response = await client.get(f"{self._base}/models", headers=self._headers())
            response.raise_for_status()
            payload = response.json()
        return [str(item["id"]) for item in payload.get("data", ()) if item.get("id")]

    async def chat(
        self,
        messages: list[dict[str, Any]],
        *,
        tools: list[dict[str, Any]] | None = None,
        temperature: float = 0.2,
    ) -> ChatResult:
        payload: dict[str, Any] = {
            "model": self._model,
            "messages": messages,
            "temperature": temperature,
        }
        if tools:
            payload["tools"] = tools
            payload["tool_choice"] = "auto"

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            response = await client.post(
                f"{self._base}/chat/completions", json=payload, headers=self._headers()
            )
            if response.status_code >= 400:
                raise InferenceError(
                    f"{self._base}/chat/completions returned HTTP {response.status_code}: "
                    f"{response.text[:BODY_EXCERPT_CHARS]}"
                )
            data = response.json()

        choices = data.get("choices") or []
        if not choices:
            raise InferenceError("Inference endpoint returned no choices.")

        choice = choices[0]
        message = choice.get("message", {})
        calls = tuple(
            ToolCall(
                id=str(call.get("id", "")),
                name=str(call.get("function", {}).get("name", "")),
                arguments=str(call.get("function", {}).get("arguments", "") or "{}"),
            )
            for call in message.get("tool_calls") or ()
        )
        return ChatResult(
            content=message.get("content") or "",
            tool_calls=calls,
            finish_reason=choice.get("finish_reason"),
        )