{
  description = "am.nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code.url = "github:sadjow/claude-code-nix?ref=latest";
    herdr.url = "github:ogulcancelik/herdr/v0.7.1";
    hermes-agent.url = "github:NousResearch/hermes-agent";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      hosts = {
        athena = "x86_64-linux";
        am = "aarch64-darwin";
      };

      mkHome =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./hosts/default.nix ];
        };
    in
    {
      homeConfigurations = lib.mapAttrs (_: mkHome) hosts;

      apps = lib.genAttrs (lib.attrValues hosts) (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          apply = pkgs.writeShellApplication {
            name = "apply";
            runtimeInputs = [ home-manager.packages.${system}.default ];
            text = ''
              host="''${1:?Error: Please specify a host name.}"
              home-manager switch --flake ".#$host"
              exec zsh
            '';
          };
        in
        {
          default = {
            type = "app";
            program = lib.getExe apply;
          };
        }
      );
    };
}
