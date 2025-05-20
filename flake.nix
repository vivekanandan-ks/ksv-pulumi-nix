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
          requirement = "${src}/requirements.txt";
          format = "other";
          # No setup.py, so skip default build steps
          dontBuild = true;
          # Ensure pip is available during install phase
          nativeBuildInputs = with python.pkgs; [ pip ];
          # Custom install phase: install dependencies from requirements.txt
          buildPhase = ''
            pip install --no-cache-dir -r $src/requirements.txt --prefix=$out
          '';

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
