"""Reconnaissance: what this machine is doing, read once and on request.

Contract:
- **Triggered, never a watcher.** Nothing here starts a thread, schedules
  itself, or keeps state between calls. The caller decides when to look, the
  read happens, the answer is returned, and nothing is remembered. A cockpit
  that can say what is on the machine must be able to look; a process that
  looks while nobody asked is surveillance, and the foundation rules that out.
  The difference is *who caused the read*, and this module is on the right side
  of it because it cannot cause one itself.
- **Local only.** Every fact comes from this machine's own process and socket
  tables — the same ones Activity Monitor reads. No packet is captured, no
  payload is inspected, no name is resolved over the network, and nothing is
  written anywhere. Attributing a listening port to the app that owns it is
  reconnaissance; reading the bytes going through it would be interception, and
  that is a different thing requiring a proxy and a trusted certificate.
- **Attribution is by process, not by name.** A port is credited to the ``.app``
  whose process tree owns it, so a model server running as a bare helper
  (``python3.11``, ``omlx-server``) is still correctly attributed to the app
  that spawned it. No list of known app names takes part: an app nobody has
  heard of is attributed exactly as well as a famous one.
- **Everything is reported, nothing is filtered.** A service or connection that
  looks like noise is still returned; ranking is the caller's job. Silently
  dropping what does not match an expectation is how a cockpit starts lying by
  omission.
"""

from __future__ import annotations

import re
import subprocess
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path

from .harnesses import (
    _bundle_identity,
    app_bundle_in,
    is_system_component,
    is_web_client,
)

#: How far up a process tree to look for the ``.app`` that owns a socket. A
#: model server is usually a grandchild of the app that launched it.
_MAX_ANCESTORS = 8


@dataclass(frozen=True, slots=True)
class ListeningService:
    """One port this machine is answering on, and who owns it."""

    pid: int
    process: str
    port: int
    address: str
    app_path: str | None
    app_name: str | None

    @property
    def is_loopback(self) -> bool:
        """Whether the port is reachable only from this machine.

        The distinction matters in both directions: a loopback port is a local
        model server the person can point Sea-Star at, while an address of
        ``*`` is offered to the network and is a privacy fact worth surfacing.
        """

        return self.address.startswith("127.") or self.address in ("::1", "localhost")

    @property
    def base_url(self) -> str:
        """The OpenAI-compatible root this port would serve, if it serves one."""

        return f"http://127.0.0.1:{self.port}/v1"


@dataclass(frozen=True, slots=True)
class OutboundConnection:
    """One live connection leaving a process on this machine."""

    pid: int
    process: str
    local: str
    remote_host: str
    remote_port: int
    app_path: str | None
    app_name: str | None

    @property
    def is_local_link(self) -> bool:
        """Whether both ends are on this machine (app talking to its own server)."""

        return self.remote_host.startswith("127.") or self.remote_host in ("::1", "localhost")

    @property
    def is_secure(self) -> bool:
        return self.remote_port == 443


def _run(command: list[str], timeout: int = 10) -> str:
    try:
        result = subprocess.run(
            command, capture_output=True, text=True, timeout=timeout, check=False
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    return result.stdout


def process_table() -> dict[int, tuple[int, str]]:
    """``pid -> (parent pid, command)`` for every process, in one read.

    One ``ps`` for the whole read rather than one per socket: attribution needs
    the whole tree, and a table built once cannot disagree with itself partway
    through a scan.
    """

    table: dict[int, tuple[int, str]] = {}
    for line in _run(["ps", "-ax", "-o", "pid=", "-o", "ppid=", "-o", "command="]).splitlines():
        parts = line.split(None, 2)
        if len(parts) != 3 or not parts[0].isdigit() or not parts[1].isdigit():
            continue
        table[int(parts[0])] = (int(parts[1]), parts[2])
    return table


def owning_app(pid: int, table: dict[int, tuple[int, str]]) -> tuple[str | None, str | None]:
    """``(app path, display name)`` of the ``.app`` whose process tree owns ``pid``.

    Walks up the parents, because a socket is usually held by a helper a few
    rungs below the app a person would recognise. Returns ``(None, None)`` when
    the chain leaves the app world entirely — a bare ``python3`` started by hand
    genuinely belongs to no app, and saying otherwise would invent an owner.
    """

    current = pid
    for _ in range(_MAX_ANCESTORS):
        entry = table.get(current)
        if entry is None:
            return None, None
        parent, command = entry
        app = app_bundle_in(command)
        if app is None:
            # A process launched from inside a bundle without the path in its
            # command line still names the bundle in its executable path.
            candidate = Path(command.split(None, 1)[0]) if command else None
            if candidate is not None:
                for part in candidate.parents:
                    if part.name.endswith(".app"):
                        app = part
                        break
        if app is not None:
            identity = _bundle_identity(app)
            name = identity[1] if identity is not None else app.stem
            return str(app), name
        if parent <= 1:
            return None, None
        current = parent
    return None, None


_LOOPBACK_V4 = re.compile(r"^(\d+\.\d+\.\d+\.\d+):(\d+)$")
_BRACKET_V6 = re.compile(r"^\[(.+)\]:(\d+)$")
_WILDCARD = re.compile(r"^\*:(\d+)$")


def _split_address(text: str) -> tuple[str, int] | None:
    """``(host, port)`` from lsof's ``-nP`` form, which never resolves names."""

    if match := _WILDCARD.match(text):
        return "*", int(match.group(1))
    if match := _LOOPBACK_V4.match(text):
        return match.group(1), int(match.group(2))
    if match := _BRACKET_V6.match(text):
        return match.group(1), int(match.group(2))
    # lsof prints the local end of a connection with a bare port when the
    # address is not interesting, and some v6 forms come through unqualified.
    if text.startswith("*") or not text:
        return None
    host, _, port = text.rpartition(":")
    if port.isdigit():
        return host or "*", int(port)
    return None


def _lsof(selection: str) -> list[list[tuple[str, str]]]:
    """Parse ``lsof -F`` output into records of ``(field, value)`` pairs.

    The field form is used rather than the column form on purpose: columns shift
    with long commands and IPv6 addresses, and a cockpit that misreads its own
    machine is worse than one that admits it cannot read it.
    """

    records: list[list[tuple[str, str]]] = []
    current: list[tuple[str, str]] = []
    for line in _run(["lsof", "-nP", "-iTCP", selection, "-F", "pcn"]).splitlines():
        if not line:
            continue
        field, value = line[0], line[1:]
        if field == "p":
            if current:
                records.append(current)
            current = [(field, value)]
        elif current:
            current.append((field, value))
    if current:
        records.append(current)
    return records


def listening_services() -> tuple[ListeningService, ...]:
    """Every TCP port this machine is answering on, attributed to its owner."""

    table = process_table()
    found: dict[tuple[int, int], ListeningService] = {}
    for record in _lsof("-sTCP:LISTEN"):
        pid = next((int(v) for f, v in record if f == "p" and v.isdigit()), None)
        if pid is None:
            continue
        process = next((v for f, v in record if f == "c"), "")
        for field, value in record:
            if field != "n":
                continue
            split = _split_address(value)
            if split is None:
                continue
            host, port = split
            app_path, app_name = owning_app(pid, table)
            found[(pid, port)] = ListeningService(
                pid=pid,
                process=process,
                port=port,
                address=host,
                app_path=app_path,
                app_name=app_name,
            )
    return tuple(found[key] for key in sorted(found))


def outbound_connections() -> tuple[OutboundConnection, ...]:
    """Every live outbound TCP connection, attributed to the app that made it."""

    table = process_table()
    seen: set[tuple[int, str, int]] = set()
    result: list[OutboundConnection] = []
    for record in _lsof("-sTCP:ESTABLISHED"):
        pid = next((int(v) for f, v in record if f == "p" and v.isdigit()), None)
        if pid is None:
            continue
        process = next((v for f, v in record if f == "c"), "")
        for field, value in record:
            if field != "n" or "->" not in value:
                continue
            _, _, remote = value.partition("->")
            split = _split_address(remote)
            if split is None:
                continue
            host, port = split
            key = (pid, host, port)
            if key in seen:
                continue
            seen.add(key)
            local_text = value.partition("->")[0]
            app_path, app_name = owning_app(pid, table)
            result.append(
                OutboundConnection(
                    pid=pid,
                    process=process,
                    local=local_text,
                    remote_host=host,
                    remote_port=port,
                    app_path=app_path,
                    app_name=app_name,
                )
            )
    return tuple(result)


def model_like_services(
    known_apps: Iterable[str] = (),
) -> tuple[ListeningService, ...]:
    """Loopback services that are inference, judged without a list of app names.

    A service qualifies on either of two honest grounds:

    1. **Its process tree speaks runtime vocabulary.** ``llama``, ``mlx``,
       ``ollama``, ``vllm`` — words that appear in the command line of something
       serving a model and almost nowhere else. A *vocabulary* generalises to
       software nobody has written yet; a list of app names cannot, and this
       module deliberately has none.
    2. **Its owning app is one this machine has already agreed is a harness.**
       That set comes from the caller (the register the person built by naming
       things), so Sea-Star never has to guess a name to recognise a friend.

    Whether a port actually *answers* with a model list is a separate question
    and belongs to :mod:`sea_star.config`, which is the only place allowed to
    speak HTTP. This function is a read of the machine, so it stays offline.
    """

    agreed = {name.casefold() for name in known_apps}
    return tuple(
        service
        for service in listening_services()
        if service.is_loopback
        and not _excluded(service.app_path)
        and (_speaks_runtime_vocabulary(service) or _in_register(service, agreed))
    )


def _excluded(app_path: str | None) -> bool:
    """Whether an app is barred from harness classification by its own role.

    Two categories only, both declared rather than named: a **web client** (it
    claims ``http``/``https``, which every browser must) and an **operating
    system component** (it lives under ``/System``). Neither is a judgement about
    the software; both are cases where classifying it as a harness would say
    something untrue and bury the apps that are one.
    """

    if app_path is None:
        return False
    if is_system_component(app_path):
        return True
    return is_web_client(Path(app_path), app_path)


def _in_register(service: ListeningService, agreed: set[str]) -> bool:
    """Whether a service's owner is one this machine has already agreed on.

    Matching is by **identity, not by label**, because the two are routinely
    different: the register says "Unsloth Studio" while the bundle calls itself
    "Unsloth", and the app's folder is the one address both agree on. So the
    bundle path is checked, and the path's stem, and the display name — any of
    them landing in the register is enough. Matching on the display name alone
    silently loses real endpoints, which is how this was found.
    """

    if not agreed:
        return False
    candidates = {service.app_name or "", service.app_path or ""}
    if service.app_path:
        candidates.add(Path(service.app_path).stem)
    return any(candidate.casefold() in agreed for candidate in candidates if candidate)


#: Words that appear in the process tree of something serving a model, and
#: almost nowhere else. Runtime families only — never a product list. A model
#: server that names no runtime still gets found by its app, via the register
#: the person keeps.
MODEL_VOCABULARY: tuple[str, ...] = (
    "llama",
    "ggml",
    "gguf",
    "mlx",
    "ollama",
    "vllm",
    "whisper",
    "transformers",
    "text-generation",
    "inference-server",
    "model-server",
)


def _speaks_runtime_vocabulary(service: ListeningService) -> bool:
    haystack = " ".join(
        part.lower()
        for part in (service.process, service.app_name or "", service.app_path or "")
        if part
    )
    return any(word in haystack for word in MODEL_VOCABULARY)


def machine_summary(
    known_apps: Iterable[str] = (),
    answering: Iterable[int] = (),
) -> tuple[str, ...]:
    """The machine in a few plain lines, for a caller that cannot draw it.

    Shared rather than written twice so the MCP answer and the cockpit cannot
    describe the same machine differently. The load-bearing sentence is the
    *inbuilt* case: on this machine every model server belongs to an app, and a
    caller that points itself at one is borrowing a server that dies with it.
    """

    names = tuple(known_apps)
    model_ports = {service.port for service in model_like_services(known_apps=names)}
    lines: list[str] = []

    servers = [
        service
        for service in listening_services()
        if service.is_loopback and service.port in model_ports
    ]
    if servers:
        lines.append("Model servers on this machine:")
        for service in sorted(servers, key=lambda item: item.port):
            owner = service.app_name or service.process
            if service.app_path is not None:
                lines.append(
                    f"  {service.base_url} — inside {owner} (stops when that app quits)"
                )
            else:
                lines.append(f"  {service.base_url} — {owner}")
    else:
        lines.append("No local model servers are answering.")

    behaviour = ledger_lines(names, answering)
    if behaviour:
        lines.append("What each app is doing:")
        lines.extend(behaviour)

    # Deliberately *not* filtered to recognised harnesses, unlike the ledger
    # above: what leaves this machine is a privacy fact about everything, and a
    # stranger's traffic is exactly the kind a person would want to notice.
    leaving: dict[str, set[str]] = {}
    for connection in outbound_connections():
        if connection.is_local_link:
            continue
        leaving.setdefault(connection.app_name or connection.process, set()).add(
            connection.remote_host
        )
    if leaving:
        lines.append("Connections leaving this machine right now:")
        for owner, hosts in sorted(leaving.items()):
            lines.append(f"  {owner} → {len(hosts)} host(s)")

    return tuple(lines)


@dataclass(frozen=True, slots=True)
class HarnessBehaviour:
    """What one app on this machine is actually doing with models.

    Every field is an observation, never an inference about motive. That
    restraint is the whole value: an app can explain itself, and this cannot be
    argued with.
    """

    name: str
    app_path: str | None
    #: Ports that **answered** an OpenAI-compatible model probe. This is the only
    #: thing here that may be stated as "serves models", because it is the only
    #: part that was proved.
    serves: tuple[int, ...]
    #: Whether it is currently talking to one of its own servers.
    using_own_server: bool
    #: Hosts outside this machine it is connected to right now.
    reaches_out: tuple[str, ...]
    #: Ports the app owns that *look* like model servers — loopback, owned, and
    #: carrying runtime vocabulary — but were not confirmed to answer. A hint,
    #: reported as a hint, and defaulted so a caller that only knows the proved
    #: ports can still build a row.
    listening: tuple[int, ...] = ()

    @property
    def reaches_cloud(self) -> bool:
        return bool(self.reaches_out)

    @property
    def owns_idle_server(self) -> bool:
        """Serves models, is not using its own server, and reaches outside anyway.

        The single most useful thing this type can say, and the reason it exists.
        It is stated as the observations that make it up and nothing more — an
        app doing this may have an excellent reason, and the person is the one
        who gets to judge that. Built on ``serves`` rather than ``listening`` on
        purpose: a port that never answered is not a server being neglected, it
        is a port we guessed about.
        """

        return bool(self.serves) and not self.using_own_server and self.reaches_cloud

    @property
    def unconfirmed(self) -> tuple[int, ...]:
        """Owned ports that carried the vocabulary but never answered.

        Kept apart from ``serves`` because the difference between "this answers
        as a model server" and "this looks like one" is the difference between a
        fact and a guess, and this module exists to keep those apart.
        """

        return tuple(port for port in self.listening if port not in self.serves)


def harness_ledger(
    known_apps: Iterable[str] = (),
    answering: Iterable[int] = (),
) -> tuple[HarnessBehaviour, ...]:
    """One row per app seen with a model server, a connection, or both.

    Read from the socket table and the process tree in a single pass, so no row
    can be half-true because the machine moved underneath it.

    ``answering`` is the set of ports an OpenAI-compatible probe actually
    answered on. It is supplied by the caller because probing is HTTP, and this
    module does not speak HTTP — see the contract at the top. Without it, a port
    is still reported, but only as one that *looks* like a server.
    """

    proved = frozenset(answering)
    names = tuple(known_apps)
    model_ports = {service.port for service in model_like_services(known_apps=names)}
    table = process_table()

    my_servers: dict[str, set[int]] = {}
    display: dict[str, str] = {}
    for service in listening_services():
        if service.app_path is None or not service.is_loopback:
            continue
        if service.port not in model_ports:
            continue
        my_servers.setdefault(service.app_path, set()).add(service.port)
        display[service.app_path] = service.app_name or service.process

    using: set[str] = set()
    reaching: dict[str, set[str]] = {}
    for connection in outbound_connections():
        # Attribute by the app the connection's process belongs to, resolved
        # here rather than trusted from the record, so a helper process is
        # credited to its app exactly as a listening port is.
        app_path, app_name = owning_app(connection.pid, table)
        if app_path is None:
            continue
        display.setdefault(app_path, app_name or connection.process)
        if connection.is_local_link:
            # App talking to a loopback port. The port was already separated
            # from the host by the parser, so it is read, never re-split: an
            # IPv6 address contains colons and a second split would mangle it.
            if connection.remote_port in my_servers.get(app_path, set()):
                using.add(app_path)
            continue
        reaching.setdefault(app_path, set()).add(connection.remote_host)

    for app_path in reaching:
        display.setdefault(app_path, Path(app_path).stem)

    rows: list[HarnessBehaviour] = []
    for app_path in sorted(set(my_servers) | set(reaching) | using):
        # Excluded here as well as in `harness_behaviour`, so there is no route
        # to a harness classification for a browser or an OS component — not
        # even by reading the unfiltered ledger directly.
        if _excluded(app_path):
            continue
        rows.append(
            HarnessBehaviour(
                name=display.get(app_path, Path(app_path).stem),
                app_path=app_path,
                serves=tuple(sorted(port for port in my_servers.get(app_path, set()) if port in proved)),
                listening=tuple(sorted(my_servers.get(app_path, set()))),
                using_own_server=app_path in using,
                reaches_out=tuple(sorted(reaching.get(app_path, set()))),
            )
        )
    return tuple(rows)


def harness_behaviour(
    known_apps: Iterable[str] = (),
    answering: Iterable[int] = (),
) -> tuple[HarnessBehaviour, ...]:
    """The ledger, scoped to apps that are harnesses on some evidence.

    Scoped to apps that **serve models** or that the machine **recognises**, so a
    browser's ordinary traffic does not read as though it were a harness. An app
    that serves nothing and is not recognised is still reported by the other
    reconnaissance reads — and, if it is reaching outside, it arrives as a
    register candidate instead, which is the right place for a stranger.

    One filter, used by the sentences, the bridge and the MCP answer, so the
    three cannot disagree about who is on the list.
    """

    agreed = {name.casefold() for name in known_apps}
    return tuple(
        row
        for row in harness_ledger(known_apps, answering)
        if not _excluded(row.app_path)
        and (row.listening or _is_recognised(row, agreed))
    )


def _is_recognised(row: HarnessBehaviour, agreed: set[str]) -> bool:
    candidates = {row.name.casefold()}
    if row.app_path:
        candidates.add(row.app_path.casefold())
        candidates.add(Path(row.app_path).stem.casefold())
    return bool(candidates & agreed)


def ledger_lines(
    known_apps: Iterable[str] = (),
    answering: Iterable[int] = (),
) -> tuple[str, ...]:
    """The behaviour ledger as plain sentences, for a caller that cannot draw it."""

    lines: list[str] = []
    for row in harness_behaviour(known_apps, answering):
        parts: list[str] = []
        if row.serves:
            ports = ", ".join(str(port) for port in row.serves)
            # "not using them" is deliberately not said: the server may be in
            # use by someone else — Sea-Star itself, for instance — and
            # claiming neglect would be a guess dressed as an observation.
            parts.append(f"serves models on {ports}")
            if row.using_own_server:
                parts.append("and is using them")
        # A port that carried the vocabulary but never answered is reported as
        # exactly that. Calling it a model server would have been a guess, and
        # on this machine it was: Unsloth's 8888 looks like one and does not
        # answer as one.
        if row.unconfirmed:
            ports = ", ".join(str(port) for port in row.unconfirmed)
            parts.append(f"listening on {ports}, not answering as a model server")
        if row.reaches_cloud:
            parts.append(f"reaching {len(row.reaches_out)} host(s) outside this machine")
        if not parts:
            continue
        lines.append(f"  {row.name}: " + "; ".join(parts))
        if row.owns_idle_server:
            ports = ", ".join(str(port) for port in row.serves)
            lines.append(
                f"      inbuilt server on {ports}, reaching outside instead"
            )
    return tuple(lines)
