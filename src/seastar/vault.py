"""Obsidian vault as first-class memory.

Contract:
- All filesystem access to a vault goes through :class:`Vault`.
- Paths handed to the vault are always relative to the vault root. Any attempt
  to escape the root (``..``, absolute paths, symlink targets) raises
  :class:`VaultError` — there is no such thing as a write outside the vault.
- Writes are append-only by default; replacing a note requires ``overwrite=True``
  so an agent cannot silently clobber someone's writing.
- Reads are side-effect free.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

SKIP_DIRS = frozenset({".obsidian", ".trash", ".git", ".seastar"})
TAG_PATTERN = re.compile(r"(?<!\w)#([A-Za-z0-9_\-/]+)")
WORD_PATTERN = re.compile(r"[a-z0-9]+")


class VaultError(RuntimeError):
    """Raised when a vault path is missing, escapes the root, or is unusable."""


@dataclass(frozen=True, slots=True)
class Note:
    """An immutable snapshot of one markdown note."""

    path: str
    title: str
    mtime: float
    size: int
    tags: tuple[str, ...] = ()

    def citation(self) -> str:
        stem = self.path.removesuffix(".md")
        return f"[[{stem}]]"


@dataclass(frozen=True, slots=True)
class SearchHit:
    """A note plus its relevance score for a query."""

    note: Note
    score: int


def _extract_tags(text: str) -> tuple[str, ...]:
    seen: list[str] = []
    for match in TAG_PATTERN.finditer(text):
        tag = match.group(1)
        if tag not in seen:
            seen.append(tag)
    return tuple(seen)


def _tokens(text: str) -> list[str]:
    return WORD_PATTERN.findall(text.lower())


class Vault:
    """A rooted, traversal-safe view over an Obsidian vault directory."""

    def __init__(self, root: Path) -> None:
        resolved = root.expanduser().resolve()
        if not resolved.is_dir():
            raise VaultError(f"Vault directory does not exist: {resolved}")
        self._root = resolved

    @property
    def root(self) -> Path:
        return self._root

    def _relative(self, path: str, *, must_be_markdown: bool = True) -> Path:
        if not path or Path(path).is_absolute():
            raise VaultError(f"Vault paths must be relative: {path!r}")
        if must_be_markdown and not path.endswith(".md"):
            path = f"{path}.md"
        resolved = (self._root / path).resolve()
        if resolved != self._root and self._root not in resolved.parents:
            raise VaultError(f"Path escapes the vault: {path!r}")
        return resolved

    def relative_to_root(self, path: Path) -> str:
        return path.resolve().relative_to(self._root).as_posix()

    def scan(self) -> tuple[Note, ...]:
        """Return every markdown note, newest first."""

        notes: list[Note] = []
        for path in self._root.rglob("*.md"):
            relative = path.relative_to(self._root)
            if any(part in SKIP_DIRS for part in relative.parts):
                continue
            stat = path.stat()
            text = path.read_text(encoding="utf-8", errors="replace")
            notes.append(
                Note(
                    path=relative.as_posix(),
                    title=path.stem,
                    mtime=stat.st_mtime,
                    size=stat.st_size,
                    tags=_extract_tags(text),
                )
            )
        notes.sort(key=lambda note: note.mtime, reverse=True)
        return tuple(notes)

    def list_notes(self, folder: str | None = None) -> tuple[Note, ...]:
        notes = self.scan()
        if not folder:
            return notes
        prefix = folder.strip("/") + "/"
        return tuple(note for note in notes if note.path.startswith(prefix))

    def read(self, path: str) -> str:
        target = self._relative(path)
        if not target.is_file():
            raise VaultError(f"Note not found: {path}")
        return target.read_text(encoding="utf-8")

    def search(self, query: str, *, limit: int = 10) -> tuple[SearchHit, ...]:
        """Rank notes by weighted term overlap (title hits count triple)."""

        terms = _tokens(query)
        if not terms:
            return ()
        hits: list[SearchHit] = []
        for note in self.scan():
            body = (self._root / note.path).read_text(encoding="utf-8", errors="replace").lower()
            title = note.title.lower()
            score = sum(body.count(term) for term in terms)
            score += 3 * sum(title.count(term) for term in terms)
            score += sum(2 for tag in note.tags if any(term in tag.lower() for term in terms))
            if score:
                hits.append(SearchHit(note=note, score=score))
        hits.sort(key=lambda hit: hit.score, reverse=True)
        return tuple(hits[:limit])

    def write(self, path: str, content: str, *, overwrite: bool = False) -> Path:
        target = self._relative(path)
        if target.exists() and not overwrite:
            raise VaultError(f"Note already exists (pass overwrite=True): {path}")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
        return target

    def append(self, path: str, content: str) -> Path:
        """Append ``content`` to a note, creating it (and parents) if needed."""

        target = self._relative(path)
        target.parent.mkdir(parents=True, exist_ok=True)
        separator = "" if not target.exists() or target.read_text(encoding="utf-8").endswith("\n") else "\n"
        with target.open("a", encoding="utf-8") as handle:
            handle.write(f"{separator}{content}\n")
        return target