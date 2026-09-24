"""Sea-Star — a private, local-first AI agent that lives in your Obsidian vault.

Sea-Star is both an MCP server (hosts call ``ask_seastar``) and an MCP client
(it consumes other MCP servers, such as Obsidian ones, as its own tools).
Nothing leaves the machine unless the operator explicitly configures an
inference endpoint to leave to.
"""

__all__ = ["__version__"]

__version__ = "0.1.0"