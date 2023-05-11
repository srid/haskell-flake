{
  # Since there is no flake.lock file (to avoid incongruent haskell-flake
  # pinning), we must specify revisions for *all* inputs to ensure
  # reproducibility.
  inputs = {
    nixpkgs = { };
    flake-parts = { };
    haskell-flake = { };

    haskell-multi-nix.url = "github:srid/haskell-multi-nix/package-settings-ng";
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
          packageSettings = [ inputs.haskell-multi-nix.haskellFlakeProjectOverlays.output ];
        };
        packages.default = self'.packages.haskell-flake-test;
      };
    };
}
