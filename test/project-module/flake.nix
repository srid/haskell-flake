{
  # Since there is no flake.lock file (to avoid incongruent haskell-flake
  # pinning), we must specify revisions for *all* inputs to ensure
  # reproducibility.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/870493f9a8cb0b074ae5b411b2f232015db19a65";
    flake-parts.url = "github:hercules-ci/flake-parts/758cf7296bee11f1706a574c77d072b8a7baa881";
    haskell-flake = { };

    haskell-multi-nix.url = "github:srid/haskell-multi-nix/d6ac6ccab559f886d1fc7da8cab44b99cb0c2c3d";
    haskell-multi-nix.inputs.haskell-flake.follows = "haskell-flake";
    haskell-multi-nix.inputs.nixpkgs.follows = "nixpkgs";
    haskell-multi-nix.inputs.flake-parts.follows = "flake-parts";
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.haskell-flake.flakeModule
      ];
      perSystem = { self', pkgs, ... }: {
        haskellProjects.default = {
          imports = [ inputs.haskell-multi-nix.haskellFlakeProjectModules.output ];
        };
        packages.default = self'.packages.haskell-flake-test;
      };
    };
}
