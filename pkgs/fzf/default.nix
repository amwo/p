{ pkgs, ... }:
{
  programs.fzf = {
    enable = true;

    defaultCommand = "rg --files --hidden -g '!.git'";
  };
}
