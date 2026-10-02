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
from urllib.parse import urlsplit

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
from .recon import (
    harness_behaviour,
    listening_services,
    model_like_services,
    outbound_connections,
)
from .register import (
    decide,
    discover,
    load_register,
    recognised_names,
    summarise,
)
from .register import (
    forget as forget_verdict,
)
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
    latent = detect_latent_harnesses(active=active)
    # Which endpoints *proved* they serve models. Everything else that looks like
    # one is reported as a port, not as a server — the difference between a fact
    # and a hint, and the reason this set is threaded through by hand.
    answered_ports = {urlsplit(probe.base_url).port or 0 for probe in probes}
    # What the machine has already decided, which is what makes the register's
    # question once-only — and what makes a loopback port that names no runtime
    # still recognisable as inference.
    register = load_register()
    recognised = recognised_names(register)
    pending = discover(register=register, workspace=None, home=None, include_vocabulary=False)
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
                # How far it climbed: "present" (installed) or "running" (a
                # process owns it now, but nothing answers on a port yet).
                "rung": spec.rung,
            }
            for spec in latent
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
        # Reconnaissance, read once as part of this report. The caller caused
        # this read by asking for a report; nothing here watches anything. Told
        # apart on purpose: `listening` is everything answering, `model_like`
        # is the subset Sea-Star is willing to call inference, and `outbound`
        # is what is leaving the machine right now.
        # What each harness is doing with models, as observations: what it
        # serves, whether it is using its own, and what it reaches for. This is
        # the ledger a person cannot get anywhere else, and it states facts
        # rather than motives.
        "behaviour": [
            {
                "name": row.name,
                "app_path": row.app_path,
                "serves": list(row.serves),
                "using_own_server": row.using_own_server,
                "reaches_out": len(row.reaches_out),
                "owns_idle_server": row.owns_idle_server,
            }
            for row in harness_behaviour(recognised, answered_ports)
        ],
        "listening": [
            {
                "pid": service.pid,
                "process": service.process,
                "port": service.port,
                "address": service.address,
                "loopback": service.is_loopback,
                "app_name": service.app_name,
                "app_path": service.app_path,
                "base_url": service.base_url if service.is_loopback else None,
            }
            for service in listening_services()
        ],
        "model_like": [
            {
                "port": service.port,
                "app_name": service.app_name,
                "app_path": service.app_path,
                "base_url": service.base_url,
                # Whether this port *answered* as a model server, or merely looks
                # like one. Both are reported; only one may be stated as fact.
                "answering": service.port in answered_ports,
            }
            for service in model_like_services(known_apps=recognised)
        ],
        "candidates": [
            {
                "identity": candidate.identity,
                "name": candidate.name,
                "bundle_id": candidate.bundle_id,
                "path": candidate.path,
                "evidence": list(candidate.evidence),
                "suggested_name": candidate.suggested_name,
            }
            for candidate in pending
        ],
        "outbound": [
            {
                "pid": connection.pid,
                "process": connection.process,
                "app_name": connection.app_name,
                "remote_host": connection.remote_host,
                "remote_port": connection.remote_port,
                "secure": connection.is_secure,
                "local_link": connection.is_local_link,
            }
            for connection in outbound_connections()
        ],
    }


@app.command()
def harnesses(
    scan: Annotated[
        bool,
        typer.Option("--scan", help="Also read inside app bundles — slower, but finds new things."),
    ] = False,
    workspace: Annotated[
        Path | None,
        typer.Option("--workspace", "-w", help="A project to check for agent artefacts."),
    ] = None,
) -> None:
    """Show what this machine has decided about its harnesses, and what is undecided."""

    register = load_register()
    if register:
        console.print("[bold]Decided[/bold]")
        for entry in sorted(register.values(), key=lambda item: item.name.casefold()):
            mark = "harness" if entry.is_harness else "not a harness"
            console.print(f"  {entry.name} — {mark}")
        console.print("")
    pending = discover(
        register=register,
        workspace=workspace,
        include_vocabulary=scan,
    )
    console.print(f"[bold]{summarise(pending)}[/bold]")
    for candidate in pending:
        console.print(f"  [bold]{candidate.name}[/bold]")
        for line in candidate.evidence:
            console.print(f"      {line}")
        console.print(f"      [dim]id: {candidate.identity}[/dim]")


@app.command()
def adopt(
    identity: Annotated[str, typer.Argument(help="The id shown by `sea-star harnesses`.")],
    name: Annotated[
        str, typer.Option("--name", "-n", help="What to call it. Blank keeps the found name.")
    ] = "",
) -> None:
    """Record something as a harness, so it is recognised from now on."""

    entry = _decide(identity, name, is_harness=True)
    console.print(f"[green]Recorded[/green] {entry.name} as a harness.")


@app.command()
def dismiss(
    identity: Annotated[str, typer.Argument(help="The id shown by `sea-star harnesses`.")],
) -> None:
    """Record that something is *not* a harness, so it stops being proposed."""

    entry = _decide(identity, "", is_harness=False)
    console.print(f"[green]Recorded[/green] {entry.name} as not a harness.")


@app.command()
def forget(
    identity: Annotated[str, typer.Argument(help="The id shown by `sea-star harnesses`.")],
) -> None:
    """Undo a verdict, so the question can be asked again."""

    forget_verdict(identity)
    console.print("[green]Forgotten.[/green]")


def _decide(identity: str, name: str, *, is_harness: bool):
    """Find the candidate behind an id and record the person's answer.

    The candidate is looked up rather than trusted from the command line, so the
    stored entry keeps the identity the scan actually observed — the path and the
    bundle id — instead of whatever was typed.
    """

    found = next(
        (candidate for candidate in discover() if candidate.identity == identity),
        None,
    )
    chosen = name or (found.suggested_name if found else None) or (found.name if found else identity)
    return decide(
        identity,
        name=chosen,
        is_harness=is_harness,
        bundle_id=found.bundle_id if found else None,
        path=found.path if found else None,
    )


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
        endpoints = ", ".join(f"{probe['name']} ({probe['base_url']})" for probe in report["runtimes"])
        console.print(f"Inference: {endpoints}")
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
    if report["model_like"]:
        serving = ", ".join(
            f"{entry['app_name'] or 'unnamed'} ({entry['base_url']})"
            for entry in report["model_like"]
        )
        console.print(f"Serving:  {serving}")
    leaving = [
        connection
        for connection in report["outbound"]
        if not connection["local_link"]
    ]
    if leaving:
        hosts = sorted({f"{c['remote_host']}:{c['remote_port']}" for c in leaving})
        apps = sorted({c["app_name"] or c["process"] for c in leaving})
        console.print(f"Leaving:  {', '.join(apps)} -> {len(hosts)} host(s)")
    if report["latent_harnesses"]:
        # A harness with a live process has climbed past "installed": say so,
        # rather than filing a running app under the same word as a dormant one.
        up = [h["name"] for h in report["latent_harnesses"] if h["rung"] == "running"]
        latent = [h["name"] for h in report["latent_harnesses"] if h["rung"] != "running"]
        if up:
            console.print(f"Running:  {', '.join(up)} (up, not answering yet)")
        if latent:
            console.print(f"Latent:   {', '.join(latent)}")
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
