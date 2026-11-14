"""Read where a harness says it gets its models from.

A harness that is *running* is evidence it is alive, but not evidence of what it
is doing: an IDE can be open and attached to nothing. The founder's question was
the missing half — *"the IDEs need to be shown to be hooked up to whatever they
may be hooked up to. They might be getting inference from somewhere else."*

Two families answer that, and they are deliberately different claims:

- **Observed** — the harness's own process holds a model-server socket. The
  engine already proves this in :mod:`sea_star.recon`; this module only names it.
- **Configured** — the harness's own settings file names a provider, a base URL
  and a model. Nothing is connected; the harness is *pointing* at it. This is
  the link that cannot be read off a port, because a configured provider holds no
  socket at all.

The honest limit, stated once: a configured provider is a **rung-0 declaration**.
It is not proof of traffic and is never drawn as live. It is the difference
between "I cannot see what it is using" and "I can see it is *configured* for
this, and nothing is running it" — which is a real fact worth showing.

Foundation §1 compliance: nothing here keys off an app's *name*. Each reader is
a path shape plus a vocabulary of provider keys, so a harness released last
month is degraded (unread) rather than invisible, and an unfamiliar settings file
simply yields nothing.

Privacy: only the derived triple (provider label, base URL, model id) is kept.
API keys, tokens and every other neighbouring field are never read into the
result and never leave this module. Nothing is written anywhere.
"""

from __future__ import annotations

import json
import re
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit

#: Where each known harness keeps the settings that name its inference. This is a
#: *hint table*, not a gate: an unlisted harness still appears, it simply has no
#: configured provider to report, and the caller says so rather than hiding it.
_CONFIG_PATHS: dict[str, tuple[str, ...]] = {
    "opencode": (".config/opencode/opencode.json",),
    "osaurus": (".osaurus/config.json", ".osaurus/settings.json"),
    "omlx": (".omlx/settings.json",),
    "trae": (".trae/config.json",),
    "atomic": (
        "Library/Application Support/Atomic Chat/data/providers.json",
        "Library/Application Support/Atomic Chat/config.json",
    ),
    "deepseek": (
        "Library/Application Support/DeepSeek Harness/settings.json",
        ".dsh/settings.json",
    ),
}

#: Keys a provider is *named* by, across harnesses. Vocabulary, not a list of
#: products: any harness using any of these is understood without being known.
#: Keys that mean "this is an *inference* provider", as opposed to every other
#: URL a settings file happens to contain. An MCP server is a URL too, and
#: mistaking one for a model route is the same category error as calling a port a
#: server (D-010): the shape of a claim is not the presence of a fact. Only
#: these keys, or a provider map, may produce a claim.
_MODEL_ROUTE_KEYS = frozenset({"model", "models", "provider", "providers", "baseURL", "base_url"})

#: A URL path that names an OpenAI-compatible surface. A model route ends in one
#: of these; an MCP endpoint does not.
_MODEL_PATH = re.compile(r"/(v\d+|chat/completions|models|completions|embeddings)$", re.IGNORECASE)

#: MCP endpoints, named by path, that must never be read as an inference route.
_MCP_PATH = re.compile(r"/mcp(/|$)", re.IGNORECASE)

#: A loopback base URL — the only kind that is about *this* machine. A harness
#: pointed at a cloud API is a real fact, but it is not what the graph's
#: endpoint nodes draw, so it is kept as a label and not resolved to a node.
_LOOPBACK = re.compile(r"^(https?://)?(127\.0\.0\.1|localhost|\[::1\])(:\d+)?(/.*)?$")

#: Models commonly named ``provider/model``. Split only on a base URL's own
#: spelling, never on a slash inside an id.
_SPLIT = re.compile(r"^(?P<provider>[^/]+)/(?P<model>.+)$")


@dataclass(frozen=True)
class ConfiguredProvider:
    """One harness's declared inference route.

    ``evidence`` is the *kind* of claim, never the file's contents: foundation §2
    says show the highest rung reached, and show it. A configured provider is a
    rung-0 declaration and is drawn as a stated binding, never as liveness.
    """

    harness: str
    provider: str
    base_url: str | None
    model: str | None
    evidence: str
    source_path: str

    @property
    def is_local(self) -> bool:
        """Whether the declared route is a loopback endpoint on this machine."""

        return self.base_url is not None and bool(_LOOPBACK.match(self.base_url))


def _coerce_url(value: Any) -> str | None:
    """A base URL from a config value, or ``None`` if it is not one."""

    if not isinstance(value, str) or "://" not in value:
        return None
    return value.rstrip("/")


def _is_model_route(url: str | None) -> bool:
    """Whether a URL is an inference surface rather than some other kind.

    Two things disqualify it: an MCP endpoint, which is a *tool* server and not a
    place models come from, and a path that does not name an OpenAI-compatible
    surface. A bare loopback port with no path is admitted, because that is how
    most local servers answer (``http://127.0.0.1:1337``) and the owning process
    is proven elsewhere — this reader only claims what the harness *declared*.
    """

    if not url:
        return False
    if _MCP_PATH.search(url):
        return False
    path = urlsplit(url).path.rstrip("/")
    if not path:
        return True
    return bool(_MODEL_PATH.search(path))


def _walk(node: Any, out: dict[str, Any]) -> dict[str, Any]:
    """Flatten one nested JSON object into ``out``, shallowly and read-only."""

    if isinstance(node, dict):
        for key, value in node.items():
            out.setdefault(key, value)
            if isinstance(value, dict):
                _walk(value, out)
    return out


def _read_json(path: Path) -> Any | None:
    """Parse one JSON file, or ``None`` if it is absent, unreadable or not JSON.

    Tolerantly on purpose: a settings file being rewritten under us, or being a
    format we do not know, must degrade this one claim to absent rather than fail
    the whole read — the foundation's rule is that a missing name never removes
    what is displayed.
    """

    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError, UnicodeDecodeError):
        return None


def _model_and_provider(flat: dict[str, Any]) -> tuple[str | None, str | None]:
    """The declared model id and the provider it was written under.

    Harnesses spell a model either bare (``qwen3-large``) or qualified
    (``omlx/qwen3-large``); the qualified form names its own provider, which is
    exactly the link the graph needs and the reason a bare id is weaker evidence.
    """

    declared = flat.get("model") or flat.get("models")
    names: list[str]
    if isinstance(declared, str):
        names = [declared] if declared.strip() else []
    elif isinstance(declared, list):
        names = [item for item in declared if isinstance(item, str) and item.strip()]
    else:
        names = []

    if not names:
        return None, None
    match = _SPLIT.match(names[0].strip())
    if match:
        return match.group("provider"), match.group("model")
    return None, names[0].strip()


def _first_url(value: Any) -> str | None:
    """The first loopback URL inside one provider's own settings, if any."""

    flat = _walk(value, {}) if isinstance(value, dict) else {}
    for key in ("baseURL", "base_url", "url", "endpoint"):
        url = _coerce_url(flat.get(key))
        if url and _is_model_route(url) and _LOOPBACK.match(url):
            return url
    return None


def _from_mapping(
    raw: Any, *, harness: str, path: Path, label: str | None = None
) -> ConfiguredProvider | None:
    """Pull one declared route out of a settings mapping, if it names one."""

    if not isinstance(raw, dict):
        return None
    flat = _walk(raw, {})
    if not _MODEL_ROUTE_KEYS & set(flat):
        return None

    provider, model = _model_and_provider(flat)
    base_url = None

    # A provider declared as a *map* of name to its own settings is the richest
    # form, because it names both halves at once, and it is resolved *first*:
    # ``_walk`` flattens nested dictionaries, so a cloud URL belonging to some
    # other provider would otherwise be picked up as a top-level ``url`` before
    # the loopback route this harness actually uses is ever considered. A
    # loopback route is preferred throughout, because a loopback endpoint is a
    # fact the machine's own graph can draw and a cloud provider never is.
    providers_map = flat.get("providers")
    if isinstance(providers_map, dict):
        for name, spec in providers_map.items():
            url = _first_url(spec) or _coerce_url(spec)
            if url and _is_model_route(url) and _LOOPBACK.match(url):
                provider = provider or name
                base_url = url
                break
        else:
            # No loopback route in the map: take its first *model* route, cloud
            # or not, so the claim still names where the harness is pointed. An
            # MCP server in the map is not a route to models and is skipped.
            for name, spec in providers_map.items():
                url = _first_url(spec) or _coerce_url(spec)
                if url and _is_model_route(url):
                    provider = provider or name
                    base_url = url
                    break

    if base_url is None:
        for key in ("baseURL", "base_url"):
            candidate = _coerce_url(flat.get(key))
            if candidate and _is_model_route(candidate):
                base_url = candidate
                break

    if base_url is None and model is not None:
        # A declared model with no URL anywhere is still a claim: the harness
        # names the model it uses. The graph cannot draw it to an endpoint, so it
        # stays a label — and the absence of a URL is itself the honest fact.
        urls = [
            url
            for url in (_coerce_url(v) for v in flat.values() if isinstance(v, str))
            if url and _is_model_route(url)
        ]
        local = [url for url in urls if _LOOPBACK.match(url)]
        base_url = (local or urls or [None])[0]

    if provider is None:
        named = flat.get("provider")
        if isinstance(named, str) and named.strip() and not _is_model_route(named):
            provider = named.strip()
    if provider is None and label:
        provider = label

    # Nothing identifying at all is not a claim worth showing.
    if provider is None and base_url is None and model is None:
        return None

    return ConfiguredProvider(
        harness=harness,
        provider=provider or (base_url or "unnamed"),
        base_url=base_url,
        model=model,
        evidence="configured",
        source_path=str(path),
    )


def detect_configured_providers(
    *, home: Path | None = None, keys: Iterable[str] | None = None
) -> tuple[ConfiguredProvider, ...]:
    """Every harness on this machine that *declares* where it gets models from.

    ``keys`` overrides the hint table's identities, so a test can point the
    reader at a temporary home without touching the real one. One claim per
    harness: a config naming two providers still reports the first, because the
    graph draws one route per harness and inventing a second node would be a
    claim about which one the person actually used.
    """

    base = (home or Path.home()).expanduser()
    table = dict(_CONFIG_PATHS) if keys is None else {}
    if keys is not None:
        table = {key: _CONFIG_PATHS.get(key, ()) for key in keys}

    found: dict[str, ConfiguredProvider] = {}
    for harness, relatives in table.items():
        for relative in relatives:
            path = base / relative
            if not path.is_file():
                continue
            claim = _from_mapping(_read_json(path), harness=harness, path=path)
            if claim is not None:
                found.setdefault(harness, claim)
            break
    return tuple(found.values())


def providers_for(harness: str, claims: Iterable[ConfiguredProvider]) -> list[ConfiguredProvider]:
    """The claims belonging to one harness, matched by identity rather than name.

    Matching is case-folded, space-stripped and substring-tolerant in both
    directions, so a harness the caller names ``DeepSeek Harness`` finds a claim
    filed under ``deepseek``. Neither a name's absence nor a mismatch may hide
    the claim: a miss returns an empty list rather than a guess, so the caller can
    say "nothing configured", which is true.
    """

    needle = _identity_key(harness)
    if not needle:
        return []
    return [
        claim
        for claim in claims
        if needle == _identity_key(claim.harness)
        or (len(needle) >= 3 and needle in _identity_key(claim.harness))
        or (len(_identity_key(claim.harness)) >= 3 and _identity_key(claim.harness) in needle)
    ]


def _identity_key(name: str) -> str:
    """A name reduced to something comparable: case-folded, no spaces or dashes."""

    return re.sub(r"[\s_\-]+", "", name).casefold()
