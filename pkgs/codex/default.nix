{ pkgs, ... }:
{
  programs.codex = {
    enable = true;
    # config.toml is intentionally NOT managed here: `codex plugin ...` mutates
    # it at runtime (marketplace/plugin/MCP entries), which fails when it is a
    # read-only Nix store symlink. config.toml is therefore owned by codex; the
    # runtime defaults below are applied at launch instead of being written into
    # config.toml.
  };

  home.shellAliases = {
    codex = "codex -a never -s workspace-write -c 'sandbox_workspace_write.network_access=true'";
  };
}
