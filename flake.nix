{
  description = "KSV pulumi project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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

        pythonEnv = pkgs.buildPythonApplication {
          src = gitignoreSource ./.;
          requirements = gitignoreSource ./requirements.txt;
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
