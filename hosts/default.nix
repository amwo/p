{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "antigravity-cli"
      "claude-code"
      "cursor-cli"
      "github-copilot-cli"
    ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  home = {
    username = "am";
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/am" else "/home/am";
    stateVersion = "24.11";
    sessionPath = [
      "$HOME/.nix-profile/bin"
      "$HOME/.local/bin"
    ];
  };

  imports = [
    ../modules/llm
    ../pkgs/ai-token-tools
    ../pkgs/clippy
    ../pkgs/claude-code
    ../pkgs/codex
    ../pkgs/copilot-cli
    ../pkgs/cursor-cli
    ../pkgs/direnv
    ../pkgs/eslint
    ../pkgs/fzf
    ../pkgs/antigravity-cli
    ../pkgs/gh
    ../pkgs/git
    ../pkgs/hermes-agent
    ../pkgs/htop
    ../pkgs/jq
    ../pkgs/less
    ../pkgs/llama-cpp-local
    ../pkgs/loop-ctl
    ../pkgs/neovim
    ../pkgs/nodejs
    ../pkgs/nixfmt
    ../pkgs/prettier
    ../pkgs/ripgrep
    ../pkgs/rust
    ../pkgs/rustfmt
    ../pkgs/tmux
    ../pkgs/zsh
  ];

  programs.home-manager.enable = true;
}
