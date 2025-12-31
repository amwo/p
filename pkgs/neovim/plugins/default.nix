{ pkgs }:

let
  conform = import ./conform { inherit pkgs; };
  nerdtree = import ./nerdtree { inherit pkgs; };
  fzf = import ./fzf { inherit pkgs; };
in
[
  conform
  fzf
  nerdtree
]
