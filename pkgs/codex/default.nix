{ pkgs, ... }:
{
  programs.codex = {
    enable = true;
    # config.toml is intentionally NOT managed here: `codex plugin ...` mutates
    # it at runtime (marketplace/plugin/MCP entries), which fails when it is a
    # read-only Nix store symlink. config.toml is therefore owned by codex; the
    # YOLO defaults (approval_policy / sandbox_mode) are seeded as a real file
    # once and preserved across plugin edits (plugins append, never overwrite).
  };
}
