{ pkgs, inputs, ... }:
{
  programs.claude-code = {
    enable = true;
    package = inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default;
    # settings.json is intentionally NOT managed here: Claude Code mutates it at
    # runtime (e.g. `/plugin install`), which fails when it is a read-only Nix
    # store symlink. The env values below are exported as real environment
    # variables instead, leaving settings.json writable and owned by Claude Code.
  };

  home.sessionVariables = {
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
    CLAUDE_CODE_TEAMMATE_MODE = "tmux";
  };
}
