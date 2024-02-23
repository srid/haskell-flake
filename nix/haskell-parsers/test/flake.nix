{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-parsers = { flake = false; }; # Overriden by nixci (see top-level flake.nix)
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem = { pkgs, lib, ... }: {
        checks.tests =
          let
            result = import (inputs.haskell-parsers + /parser_tests.nix) { inherit pkgs lib; };
          in
          pkgs.writeTextFile {
            name = "haskell-parsers-test-results";
            text = builtins.toJSON result;
          };
      };
    };
}
