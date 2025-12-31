{ pkgs, ... }:
{
  home.packages = [
    pkgs.nodePackages.eslint
  ];
}
