{ pkgs, ... }:

# loop-ctl: domain-agnostic self-regulating controller for improvement loops.
# Built from the local Cargo crate; the `/improve` skill drives it.
let
  loop-ctl = pkgs.rustPlatform.buildRustPackage {
    pname = "loop-ctl";
    version = "0.1.0";
    src = ./.;
    cargoLock.lockFile = ./Cargo.lock;
  };
in
{
  home.packages = [ loop-ctl ];
}
