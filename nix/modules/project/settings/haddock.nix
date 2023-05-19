{ config, pkgs, lib, mkCabalSettingOptions, ... }:

let
  inherit (lib)
    types;
in
{
  options = mkCabalSettingOptions {
    inherit config;
    name = "haddock";
    type = types.bool;
    description = ''
      Whether to build the haddock documentation.
    '';
    impl = haddock: with pkgs.haskell.lib.compose;
      if haddock then doHaddock else dontHaddock;
  };
}
