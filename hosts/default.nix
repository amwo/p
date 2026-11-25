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

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  home = {
    username = "am";
    homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/am" else "/home/am";
    stateVersion = "24.11";
    sessionPath = [
      "$HOME/.nix-profile/bin"
      "$HOME/.local/bin"
    ];
  };

  imports =
    [ ../modules/llm ]
    ++ map (name: ../pkgs/${name}) (
      lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../pkgs))
    );

  programs.home-manager.enable = true;
}
