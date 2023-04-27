# A flake-parts module for Haskell cabal projects.
{ self, lib, flake-parts-lib, ... }:

let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo
    raw;
in
{
  imports = [
    ./modules/haskell-flake-project-modules.nix
    ./modules/haskell-projects.nix
  ];
}
