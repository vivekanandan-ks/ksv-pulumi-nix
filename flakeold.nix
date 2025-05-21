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
            #from pypi (add only in requirements.txt)
            import (gitignoreSource ./requirements.nix)
            
            #from nixpkgs (add here below)
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
            pulumi-bin
            pulumiPackages.pulumi-python
            awscli2
            uv
            
          ];
          shellHook = ''
            ${install-requirements}/bin/install-requirements
            echo "welcome to the pulumi shell created by https://github.com/vivekanandan-ks" | ${pkgs.cowsay}/bin/cowsay
            #my custom fish shel prompt customized (comment below to use defualt bash)
            exec ${pkgs.fish}/bin/fish --init-command '
            function fish_prompt
                # Get exit status of last command
                set -l last_status $status
                if test $last_status -eq 0
                    set_color green
                    echo -n "✓ "
                else
                    set_color red
                    echo -n "$last_status "
                end
                set_color normal

                # Get git branch name, if applicable
                set -l git_branch (git symbolic-ref --short HEAD 2>/dev/null)
                if test -n "$git_branch"
                    set_color yellow
                    echo -n "[$git_branch] "
                    set_color normal
                end

                # Prompt prefix
                set_color blue
                echo -n "nix-shell🐠🐚> "
                set_color normal
            end'
            #export LD_LIBRARY_PATH=${pkgs.gcc.cc.lib}/lib:$LD_LIBRARY_PATH
          '';
        };
      });
}
