{
  # Disable IFD for this test.
  nixConfig = {
    allow-import-from-derivation = false;
  };

  # Since there is no flake.lock file (to avoid incongruent haskell-flake
  # pinning), we must specify revisions for *all* inputs to ensure
  # reproducibility.
  inputs = {
    nixpkgs = { };
    flake-parts = { };
    haskell-flake = { };
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.haskell-flake.flakeModule
      ];
      debug = true;
      perSystem = { config, self', pkgs, lib, ... }: {
        haskellProjects.default = {
          # If IFD is disabled, 
          # we need to specify the pre-generated `cabal2nix` expressions
          # file to haskell-flake for the package, 
          # otherwise build would fail as it would use `callCabal2nix` function
          # which uses IFD.
          packages.haskell-flake-test.cabal2NixFile = "default.nix";
          settings = { };
        };
      };
    };
}
