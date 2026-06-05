{ pkgs, ... }:
{
  programs.antigravity-cli = {
    enable = true;
  };

  home.shellAliases = {
    agy = "agy --approval-mode=yolo";
  };
}
