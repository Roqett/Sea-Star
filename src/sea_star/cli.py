"""The ``sea-star`` command line.

Contract:
- ``init`` writes a config into a vault; ``doctor`` reports whether the machine is
  ready; ``ask`` runs one agent query; ``serve`` runs the MCP server over stdio.
- Commands fail loud: a missing vault, an unreachable runtime, or a config error
  exits non-zero with a plain-language message, never a silent fallback.
"""

from __future__ import annotations

import asyncio
import json
from pathlib import Path
from typing import Annotated

import typer
from rich.console import Console
from rich.markup import escape

from . import __version__
from .agent import build_agent
from .agents import detect_agent_roster
from .config import (
    ConfigError,
    detect_vault_candidates,
    load_config,
    probe_base_url,
    probe_runtimes,
    read_config_file,
    resolve_vault,
    write_default_config,
)
from .connections import clear_client, live_clients, record_client
from .harnesses import detect_latent_harnesses
from .mcp_server import create_server
from .vault import Vault

app = typer.Typer(
    name="sea-star",
    help="A private, local-first AI agent that lives in your Obsidian vault.",
    no_args_is_help=True,
    add_completion=False,
)
console = Console()

BRIDGE_SCHEMA_VERSION = 1


def _die(message: str) -> None:
    console.print(f"[bold red]Error:[/bold red] {escape(message)}")
    raise typer.Exit(code=1)


async def _build_report() -> dict:
    """Assemble the §6 bridge object the host app decodes."""

    vault_path, vault_source = resolve_vault(read_config_file())
    probes = await probe_runtimes()
    config = await load_config(probes=probes)
    # Trust the resolved probe's model list when there is one: it carries the
    # Osaurus fix-up (the configured model in place of ``foundation``), which a
    # fresh probe of the same endpoint would not.
    live = next((probe for probe in probes if probe.base_url == config.base_url), None)
    models = list(live.models) if live is not None else await probe_base_url(config.base_url)
    roster = detect_agent_roster(vault_path)
    # §3, ask, don't guess: a host attached over stdio never answers a port
    # probe, so its own live connection record is the only honest signal.
    clients = live_clients()
    active = {probe.name for probe in probes}
    active.update(client.name for client in clients)
    return {
        "schema_version": BRIDGE_SCHEMA_VERSION,
        "ready": bool(models),
        "version": __version__,
        "vault": {
            "path": str(vault_path),
            "source": vault_source,
            "note_count": len(Vault(vault_path).scan()),
            "candidates": [str(path) for path in detect_vault_candidates()],
        },
        "runtime": config.runtime_name,
        "base_url": config.base_url,
        "model": config.model,
        "models": models or [],
        "agents": [
            {
                "name": spec.name,
                "model": spec.model,
                "description": spec.description,
            }
            for spec in roster.specs
        ],
        # Which adapter produced ``agents`` above. A roster belongs to the app it
        # was read from, so the app can say so instead of implying it is the
        # machine's roster. ``None`` means no roster was found at all, which is
        # a different fact from "found, and empty".
        "agent_source": roster.source,
        "latent_harnesses": [
            {
                "name": spec.name,
                "bundle_id": spec.bundle_id,
                "path": spec.path,
            }
            for spec in detect_latent_harnesses(active=active)
        ],
        "mcp_clients": [
            {
                "name": client.name,
                "bundle_id": client.bundle_id,
                "pid": client.pid,
                "started_at": client.started_at,
            }
            for client in clients
        ],
        "runtimes": [
            {
                "name": probe.name,
                "base_url": probe.base_url,
                "model": probe.model,
                "models": list(probe.models),
            }
            for probe in probes
        ],
        "server": {"state": "running" if models else "stopped"},
        "servers": [
            {
                "name": spec.name,
                "command": spec.command,
                "include": list(spec.include),
                "exclude": list(spec.exclude),
            }
            for spec in config.servers
        ],
    }


@app.command()
def version() -> None:
    """Print the Sea-Star version."""

    console.print(f"sea-star {__version__}")


@app.command()
def init(
    vault: Annotated[Path, typer.Option("--vault", "-v", help="Path to your Obsidian vault.")],
    model: Annotated[str, typer.Option("--model", "-m", help="Model name (blank = autodetect).")] = "",
    base_url: Annotated[str, typer.Option("--base-url", help="Inference endpoint (blank = autodetect).")] = "",
) -> None:
    """Write a seastar.toml into a vault and create local state."""

    vault = vault.expanduser().resolve()
    if not vault.is_dir():
        _die(f"Vault directory does not exist: {vault}")
    path = write_default_config(vault, model=model, base_url=base_url)
    (vault / ".seastar").mkdir(exist_ok=True)
    console.print(f"[green]Configured[/green] {path}")
    console.print("Next: [bold]sea-star doctor[/bold]")


@app.command()
def doctor(
    as_json: Annotated[
        bool, typer.Option("--json", help="Emit a machine-readable status report.")
    ] = False,
) -> None:
    """Check the vault, the inference runtime, and the available models.

    With ``--json`` this prints a single JSON object to stdout and is the bridge
    contract a host app (the macOS app, an Obsidian plugin) can poll: it always
    emits JSON, even on failure, so the caller never has to parse prose.
    """

    try:
        report = asyncio.run(_build_report())
    except ConfigError as error:
        if as_json:
            print(json.dumps({"ready": False, "error": str(error)}))
            raise typer.Exit(code=1)
        _die(str(error))

    if as_json:
        print(json.dumps(report))
        if not report["ready"]:
            raise typer.Exit(code=1)
        return

    console.print(f"Vault:    [green]{report['vault']['path']}[/green] ({report['vault']['source']})")
    console.print(f"Notes:    {report['vault']['note_count']}")
    console.print(f"Runtime:  {report['runtime']} -> {report['base_url']}")
    console.print(f"Model:    {report['model']}")
    if len(report["runtimes"]) > 1:
        harnesses = ", ".join(f"{probe['name']} ({probe['base_url']})" for probe in report["runtimes"])
        console.print(f"Harnesses: {harnesses}")
    if not report["ready"]:
        _die(f"Runtime at {report['base_url']} did not answer. Start it and retry.")
    console.print(f"Available: {', '.join(report['models'][:8])}")
    if report["servers"]:
        names = ", ".join(server["name"] for server in report["servers"])
        console.print(f"Bridged MCP servers: {names}")
    else:
        console.print("Bridged MCP servers: none")
    if report["agents"]:
        names = ", ".join(agent["name"] for agent in report["agents"])
        console.print(f"Agents:   {names}")
    if report["mcp_clients"]:
        names = ", ".join(client["name"] for client in report["mcp_clients"])
        console.print(f"Connected: {names}")
    if report["latent_harnesses"]:
        names = ", ".join(harness["name"] for harness in report["latent_harnesses"])
        console.print(f"Latent:   {names}")
    console.print("[green]Ready.[/green]")


@app.command()
def ask(
    question: Annotated[str, typer.Argument(help="What you want to ask your vault.")],
) -> None:
    """Run one agent query against the vault and print the cited answer."""

    async def _run() -> None:
        config = await load_config()
        agent = await build_agent(config)
        result = await agent.run(question)
        console.print(result.answer)
        if result.citations:
            console.print(f"\n[dim]Sources: {', '.join(f'[[{c}]]' for c in result.citations)}[/dim]")

    try:
        asyncio.run(_run())
    except ConfigError as error:
        _die(str(error))


@app.command()
def serve() -> None:
    """Run Sea-Star as an MCP server over stdio (for Claude Desktop, Cursor, Trae...)."""

    try:
        config = asyncio.run(load_config())
        agent = asyncio.run(build_agent(config))
    except ConfigError as error:
        _die(str(error))
    server = create_server(config, agent)
    record_client()
    try:
        server.run(transport="stdio")
    finally:
        clear_client()


if __name__ == "__main__":
    app()
