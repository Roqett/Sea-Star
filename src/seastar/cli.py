"""The ``seastar`` command line.

Contract:
- ``init`` writes a config into a vault; ``doctor`` reports whether the machine is
  ready; ``ask`` runs one agent query; ``serve`` runs the MCP server over stdio.
- Commands fail loud: a missing vault, an unreachable runtime, or a config error
  exits non-zero with a plain-language message, never a silent fallback.
"""

from __future__ import annotations

import asyncio
from pathlib import Path
from typing import Annotated

import typer
from rich.console import Console
from rich.markup import escape

from . import __version__
from .agent import build_agent
from .config import ConfigError, load_config, probe_base_url, write_default_config
from .mcp_server import create_server
from .vault import Vault

app = typer.Typer(
    name="seastar",
    help="A private, local-first AI agent that lives in your Obsidian vault.",
    no_args_is_help=True,
    add_completion=False,
)
console = Console()


def _die(message: str) -> None:
    console.print(f"[bold red]Error:[/bold red] {escape(message)}")
    raise typer.Exit(code=1)


@app.command()
def version() -> None:
    """Print the SeaStar version."""

    console.print(f"seastar {__version__}")


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
    console.print("Next: [bold]seastar doctor[/bold]")


@app.command()
def doctor() -> None:
    """Check the vault, the inference runtime, and the available models."""

    async def _run() -> None:
        config = await load_config()
        console.print(f"Vault:    [green]{config.vault_path}[/green]")
        console.print(f"Notes:    {len(Vault(config.vault_path).scan())}")
        console.print(f"Runtime:  {config.runtime_name} -> {config.base_url}")
        console.print(f"Model:    {config.model}")
        models = await probe_base_url(config.base_url)
        if not models:
            _die(f"Runtime at {config.base_url} did not answer. Start it and retry.")
        console.print(f"Available: {', '.join(models[:8])}")
        if config.servers:
            names = ", ".join(spec.name for spec in config.servers)
            console.print(f"Bridged MCP servers: {names}")
        else:
            console.print("Bridged MCP servers: none")
        console.print("[green]Ready.[/green]")

    try:
        asyncio.run(_run())
    except ConfigError as error:
        _die(str(error))


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
    """Run SeaStar as an MCP server over stdio (for Claude Desktop, Cursor, Trae...)."""

    try:
        config = asyncio.run(load_config())
        agent = asyncio.run(build_agent(config))
    except ConfigError as error:
        _die(str(error))
    server = create_server(config, agent)
    server.run(transport="stdio")


if __name__ == "__main__":
    app()