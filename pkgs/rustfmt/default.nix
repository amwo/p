{ pkgs, ... }:
{
  home.packages = [
    pkgs.rustfmt
  ];
}
