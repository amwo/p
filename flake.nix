{
  description = "am.nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      home-manager,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        {
          apps.default = {
            type = "app";
            program =
              let
                applyScript = pkgs.writeShellScriptBin "apply" ''
                  HOST=$1
                  if [ -z "$HOST" ]; then
                    echo "Error: Please specify a host name."
                    exit 1
                  fi
                  ${inputs.home-manager.packages.${system}.default}/bin/home-manager switch --flake ".#$HOST"

                  exec zsh
                '';
              in
              "${applyScript}/bin/apply";
          };
        };

      flake = {
        homeConfigurations = {
          "athena" = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages."x86_64-linux";
            modules = [ ./hosts/default.nix ];
          };
          "am" = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages."aarch64-darwin";
            modules = [ ./hosts/default.nix ];
          };
        };
      };
    };
}
