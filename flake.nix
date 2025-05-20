{
  description = "KSV pulumi project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, gitignore, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (gitignore.lib) gitignoreSource;
        pkgs = import nixpkgs { 
          inherit system;
        };
        packageOverrides = pkgs.callPackage (gitignoreSource ./python-packages.nix) {};
        python = pkgs.python313.override { inherit packageOverrides; };
        pythonEnv = python.withPackages (p: with p; [
            pulumi
            pulumi-aws
        ]);
        install-requirements = pkgs.writeShellApplication {
          name = "install-requirements";
          runtimeInputs = with pkgs; [];
          text = ''
            #!/usr/bin/env ${pkgs.bash}/bin/bash
            nix run github:nix-community/pip2nix -- ./requirements.txt
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
            

          '';
        };
      });
}
