{
  description = "KSV pulumi project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pip2nix.url = "github:nix-community/pip2nix";
  };

  outputs = { self, nixpkgs, flake-utils, gitignore, pip2nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (gitignore.lib) gitignoreSource;
        pkgs = import nixpkgs { 
          inherit system;
        };
        packageOverrides = pkgs.callPackage (gitignoreSource ./python-packages.nix) {};

        python = pkgs.python313.override { inherit packageOverrides; };
        pythonEnv = python.withPackages (p: with p; [
            import ./requirements.nix
            #from pypi
            #pulumi
            #pulumi-aws

            #from nixpkgs
        ]);
        
        install-requirements = pkgs.writeShellApplication {
          name = "install-requirements";
          runtimeInputs = [pip2nix.defaultPackage.${system}];
          text = ''
            #!/usr/bin/env ${pkgs.bash}/bin/bash
            echo "Running install-requirements..."
            ${pip2nix.defaultPackage.${system}}/bin/pip2nix generate -r ./requirements.nix
          '';
        };

      in {

        packages.install-requirements = install-requirements;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            pythonEnv
            pulumi
          ];
          shellHook = ''
            ${install-requirements}/bin/install-requirements
          '';
        };
      });
}
