{
  # Disable IFD for this test.
  nixConfig = {
    allow-import-from-derivation = false;
  };

  # Since there is no flake.lock file (to avoid incongruent haskell-flake
  # pinning), we must specify revisions for *all* inputs to ensure
  # reproducibility.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/870493f9a8cb0b074ae5b411b2f232015db19a65";
    flake-parts.url = "github:hercules-ci/flake-parts/758cf7296bee11f1706a574c77d072b8a7baa881";
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
