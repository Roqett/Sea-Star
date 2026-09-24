"""Vault behaviour: scanning, search ranking, writes, and traversal safety."""

from __future__ import annotations

import pytest

from sea_star.vault import Vault, VaultError


@pytest.fixture()
def vault(tmp_path):
    (tmp_path / "Ideas").mkdir()
    (tmp_path / "Ideas" / "ferment.md").write_text("#fermentation\nYeast and time.\n", encoding="utf-8")
    (tmp_path / "daily.md").write_text("Yeast notes for the week.\n#wine\n", encoding="utf-8")
    (tmp_path / ".obsidian").mkdir()
    (tmp_path / ".obsidian" / "secret.md").write_text("ignore me", encoding="utf-8")
    return Vault(tmp_path)


def test_scan_skips_hidden_dirs(vault):
    paths = {note.path for note in vault.scan()}
    assert paths == {"Ideas/ferment.md", "daily.md"}


def test_search_ranks_title_hits_higher(vault):
    vault.write("Yeast.md", "starter culture notes")
    hits = vault.search("yeast")
    assert hits, "expected at least one hit"
    assert hits[0].note.path == "Yeast.md"


def test_read_and_append_roundtrip(vault):
    vault.append("Ideas/ferment.md", "Second paragraph.")
    assert "Second paragraph." in vault.read("Ideas/ferment.md")


def test_append_creates_missing_note(vault):
    vault.append("new/note.md", "hello")
    assert vault.read("new/note.md").startswith("hello")


def test_read_missing_note_fails_loud(vault):
    with pytest.raises(VaultError):
        vault.read("nope.md")


def test_path_traversal_is_rejected(vault):
    with pytest.raises(VaultError):
        vault.read("../escape.md")
    with pytest.raises(VaultError):
        vault.write("/etc/passwd.md", "nope")


def test_write_refuses_to_clobber(vault):
    with pytest.raises(VaultError):
        vault.write("daily.md", "overwrite")
    vault.write("daily.md", "overwrite", overwrite=True)
    assert vault.read("daily.md") == "overwrite"


def test_note_citation_strips_extension(vault):
    note = next(n for n in vault.scan() if n.path == "daily.md")
    assert note.citation() == "[[daily]]"