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

        python = pkgs.python313;
        pythonEnv = python.pkgs.buildPythonApplication rec {
          pname = "ksv-pulumi-python-env";
          version = "1.0";
          src = gitignoreSource ./.;
          requirements = "${src}/requirements.txt";
          };

      in {

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            pythonEnv
            pulumi

          ];
        };
      });
}
