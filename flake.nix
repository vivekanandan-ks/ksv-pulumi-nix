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

      in {

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            pulumi
            pulumi-bin
            pulumiPackages.pulumi-python
            awscli2
            uv
            
          ];
          shellHook = ''
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

                # Show current directory
                set_color blue
                echo -n (prompt_pwd)
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
            end
            '

            '';
        };
      });
}
