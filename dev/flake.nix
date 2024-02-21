{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    mission-control.url = "github:Platonic-Systems/mission-control";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    haskell-flake = {};
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.flake-root.flakeModule
        inputs.mission-control.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
      perSystem = { pkgs, lib, config, ... }: {
        treefmt.config = {
          projectRoot = inputs.haskell-flake;
          projectRootFile = "README.md";
          programs.nixpkgs-fmt.enable = true;
        };
        mission-control.scripts = {
          ex = {
            description = "Run example";
            exec = "cd ./example && nix run . --override-input haskell-flake ..";
          };
          test = {
            description = "Run test";
            exec = "./runtest.sh";
          };
          fmt = {
            description = "Format all Nix files";
            exec = config.treefmt.build.wrapper;
          };
        };
        devShells.default = pkgs.mkShell {
          # cf. https://haskell.flake.page/devshell#composing-devshells
          inputsFrom = [
            config.mission-control.devShell
            config.treefmt.build.devShell
          ];
        };
      };
    };
}
