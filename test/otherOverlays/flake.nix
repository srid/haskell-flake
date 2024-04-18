{
  # Since there is no flake.lock file (to avoid incongruent haskell-flake
  # pinning), we must specify revisions for *all* inputs to ensure
  # reproducibility.
  inputs = {
    nixpkgs = { };
    flake-parts = { };
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
          otherOverlays = [
            (self: super: {
              foo = super.callCabal2nix "foo" "${inputs.haskell-multi-nix}/foo" { };
            })
          ];
        };
        packages.default = self'.packages.haskell-flake-test;
      };
    };
}
