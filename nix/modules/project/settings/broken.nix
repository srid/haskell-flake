{ config, pkgs, lib, mkCabalSettingOptions, ... }:

let
  inherit (lib)
    types;
in
{
  options = mkCabalSettingOptions {
    inherit config;
    name = "broken";
    type = types.bool;
    description = ''
      Whether to mark the package as broken
    '';
    impl = enable: with pkgs.haskell.lib.compose;
      if enable then markBroken else unmarkBroken;
  };
}
