"""Tests for the configured-provider reader.

The reader's whole job is to be honest about a weak claim: a settings file naming
a provider is a *declaration*, never proof of traffic. Most of these tests exist
to keep it that way — the negative cases matter more than the happy ones.
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from sea_star.providers import (
    ConfiguredProvider,
    detect_configured_providers,
    providers_for,
)


def _write(path: Path, payload: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload), encoding="utf-8")


# --- the shape of a claim -------------------------------------------------


def test_reads_provider_and_model_from_a_provider_slash_model(tmp_path: Path) -> None:
    _write(
        tmp_path / ".config/opencode/opencode.json",
        {"model": "atomic/Dirk-Qwen3.8-27B-MLX-oQ4e"},
    )
    (claim,) = detect_configured_providers(home=tmp_path, keys=["opencode"])
    assert claim.harness == "opencode"
    assert claim.provider == "atomic"
    assert claim.model == "Dirk-Qwen3.8-27B-MLX-oQ4e"
    # A declaration is a declaration: rung 0, and it never claims liveness.
    assert claim.evidence == "configured"


def test_reads_a_base_url_and_reports_it_as_local(tmp_path: Path) -> None:
    _write(
        tmp_path / ".config/opencode/opencode.json",
        {"provider": "omlx", "baseURL": "http://127.0.0.1:8009/v1"},
    )
    (claim,) = detect_configured_providers(home=tmp_path, keys=["opencode"])
    assert claim.provider == "omlx"
    assert claim.base_url == "http://127.0.0.1:8009/v1"
    assert claim.is_local is True


def test_a_cloud_route_is_kept_as_a_label_and_is_not_local(tmp_path: Path) -> None:
    _write(
        tmp_path / ".config/opencode/opencode.json",
        {"model": "openrouter/some-model", "baseURL": "https://openrouter.ai/api/v1"},
    )
    (claim,) = detect_configured_providers(home=tmp_path, keys=["opencode"])
    assert claim.is_local is False
    # It is still a real fact, so it is still reported — just never as a node.
    assert claim.provider == "openrouter"


def test_nested_provider_map_yields_its_first_local_route(tmp_path: Path) -> None:
    _write(
        tmp_path / ".config/opencode/opencode.json",
        {
            "providers": {
                "somebody": {"baseURL": "https://example.invalid/v1"},
                "atomic": {"baseURL": "http://127.0.0.1:1337/v1"},
            }
        },
    )
    (claim,) = detect_configured_providers(home=tmp_path, keys=["opencode"])
    # The loopback route wins over the cloud one: it is the only one the
    # machine's own graph can draw a node for.
    assert claim.provider == "atomic"
    assert claim.base_url == "http://127.0.0.1:1337/v1"


# --- degrading rather than vanishing (foundation §1) ----------------------


def test_a_missing_config_yields_no_claim_and_raises_nothing(tmp_path: Path) -> None:
    assert detect_configured_providers(home=tmp_path, keys=["opencode"]) == ()


def test_malformed_json_degrades_to_absent_rather_than_failing(tmp_path: Path) -> None:
    path = tmp_path / ".config/opencode/opencode.json"
    path.parent.mkdir(parents=True)
    path.write_text("{not json at all", encoding="utf-8")
    assert detect_configured_providers(home=tmp_path, keys=["opencode"]) == ()


def test_a_config_naming_nothing_recognisable_yields_no_claim(tmp_path: Path) -> None:
    _write(tmp_path / ".config/opencode/opencode.json", {"theme": "dark", "font": "mono"})
    assert detect_configured_providers(home=tmp_path, keys=["opencode"]) == ()


def test_an_unlisted_harness_is_unread_not_invisible(tmp_path: Path) -> None:
    """A harness with no entry in the hint table simply has no claim.

    It is not dropped from the machine's picture — that is the caller's roster
    job. This module only declines to invent a route for it.
    """

    _write(tmp_path / ".config/opencode/opencode.json", {"model": "x/y"})
    assert detect_configured_providers(home=tmp_path, keys=["never-heard-of-it"]) == ()
    # …and the harness that *is* listed still reads, in the same sweep.
    assert len(detect_configured_providers(home=tmp_path, keys=["opencode", "x"])) == 1


# --- privacy: derived fields only ----------------------------------------


def test_a_config_full_of_secrets_yields_only_the_derived_triple(tmp_path: Path) -> None:
    """The whole reason this module is separate: it must not carry a key.

    A real settings file sits next to credentials. Only the provider label, base
    URL and model id may leave; an API key must not appear anywhere in a claim.
    """

    _write(
        tmp_path / ".config/opencode/opencode.json",
        {
            "model": "atomic/Dirk",
            "baseURL": "http://127.0.0.1:1337/v1",
            "apiKey": "sk-super-secret-value",
            "authToken": "another-secret",
            "password": "hunter2",
        },
    )
    (claim,) = detect_configured_providers(home=tmp_path, keys=["opencode"])
    rendered = repr(claim)
    for secret in ("sk-super-secret-value", "another-secret", "hunter2"):
        assert secret not in rendered
    # And no attribute smuggles the raw document along either.
    assert not hasattr(claim, "raw")


def test_a_claim_is_frozen_so_nothing_can_mutate_it_in_place(tmp_path: Path) -> None:
    _write(tmp_path / ".config/opencode/opencode.json", {"model": "a/b"})
    (claim,) = detect_configured_providers(home=tmp_path, keys=["opencode"])
    assert isinstance(claim, ConfiguredProvider)
    with pytest.raises((AttributeError, TypeError)):
        claim.provider = "rewritten"  # type: ignore[misc]


# --- identity matching ----------------------------------------------------


def test_an_mcp_server_url_is_never_read_as_an_inference_route(tmp_path: Path) -> None:
    """The live bug, pinned.

    This machine's real ``~/.config/opencode/opencode.json`` declares two *MCP
    servers* and no model at all. A reader that accepted "any URL" reported the
    Exa MCP endpoint as OpenCode's model provider — the same category error as
    D-010's "a port is not a server": the presence of a URL is not the shape of a
    model claim. Only an inference surface, or an explicit model/provider key,
    may produce one.
    """

    _write(
        tmp_path / ".config/opencode/opencode.json",
        {
            "mcp": {
                "exa": {"type": "remote", "url": "https://mcp.exa.ai/mcp", "enabled": True},
                "mcpbridge": {
                    "type": "local",
                    "command": ["/Applications/Xcode.app/Contents/Developer/usr/bin/mcpbridge"],
                    "enabled": True,
                },
            }
        },
    )
    # No model, no provider key: there is no claim to make, and none is made.
    assert detect_configured_providers(home=tmp_path, keys=["opencode"]) == ()


def test_an_mcp_url_beside_a_real_model_claim_does_not_win(tmp_path: Path) -> None:
    """A declared model still reads; the MCP URL must not be mistaken for it."""

    _write(
        tmp_path / ".config/opencode/opencode.json",
        {
            "model": "atomic/Dirk-Qwen3.8-27B-MLX-oQ4e",
            "mcp": {"exa": {"type": "remote", "url": "https://mcp.exa.ai/mcp"}},
        },
    )
    (claim,) = detect_configured_providers(home=tmp_path, keys=["opencode"])
    assert claim.provider == "atomic"
    assert claim.model == "Dirk-Qwen3.8-27B-MLX-oQ4e"
    # No URL was claimed at all, rather than the MCP one being borrowed.
    assert claim.base_url is None
    assert "exa" not in claim.provider


def test_an_openai_shaped_path_is_accepted(tmp_path: Path) -> None:
    _write(
        tmp_path / ".config/opencode/opencode.json",
        {"provider": "somebody", "baseURL": "https://example.invalid/v1"},
    )
    (claim,) = detect_configured_providers(home=tmp_path, keys=["opencode"])
    assert claim.base_url == "https://example.invalid/v1"
    assert claim.is_local is False


def test_a_bare_loopback_port_is_accepted(tmp_path: Path) -> None:
    """Local servers answer without a path, so ``/v1`` must not be required."""

    _write(
        tmp_path / ".config/opencode/opencode.json",
        {"model": "atomic/Dirk", "baseURL": "http://127.0.0.1:1337"},
    )
    (claim,) = detect_configured_providers(home=tmp_path, keys=["opencode"])
    assert claim.base_url == "http://127.0.0.1:1337"
    assert claim.is_local is True


def test_providers_for_matches_a_display_name_against_a_key(tmp_path: Path) -> None:
    _write(tmp_path / ".dsh/settings.json", {"model": "deepseek/chat"})
    claims = detect_configured_providers(home=tmp_path, keys=["deepseek"])
    assert providers_for("DeepSeek Harness", claims)
    # A name we hold nothing for returns empty, so the caller can say
    # "nothing configured" rather than guessing at a neighbour.
    assert providers_for("Some Other App", claims) == []
