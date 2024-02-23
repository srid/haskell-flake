{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake = { }; # Overriden by nixci (see top-level flake.nix)
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem = { pkgs, ... }: {
        checks.tests = pkgs.runCommandNoCC "tests"
          {
            nativeBuildInputs = with pkgs; [
              coreutils
              bash
              nix
              cacert
              git
              which
              gawk
            ];
          } ''
          export HOME=$(mktemp -d)
          cd $HOME
          mkdir -p .config/nix
          echo 'experimental-features = nix-command flakes' > .config/nix/nix.conf
          cp -r ${inputs.haskell-flake} ./haskell-flake
          chmod -R u+rw haskell-flake
          cd haskell-flake
          git config --global user.email "nix@localhost"
          git config --global user.name "nix"
          git init && git add . && git commit -m "Initial commit"
          bash ./runtest.sh 
          touch $out
        '';
      };
    };
}
