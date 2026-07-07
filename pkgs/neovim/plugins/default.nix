{ pkgs }:

let
  conform = import ./conform { inherit pkgs; };
  neo-tree = import ./neo-tree { inherit pkgs; };
  fzf = import ./fzf { inherit pkgs; };
in
[
  conform
  fzf
  neo-tree
]
