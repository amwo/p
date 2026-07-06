{ pkgs, ... }:
{
  programs.codex = {
    enable = true;
    # config.toml is intentionally NOT managed here: `codex plugin ...` mutates
    # it at runtime (marketplace/plugin/MCP entries), which fails when it is a
    # read-only Nix store symlink. Runtime defaults are merged by modules/llm.
  };
}
