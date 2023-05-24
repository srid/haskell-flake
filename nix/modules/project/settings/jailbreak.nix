{ config, pkgs, lib, mkCabalSettingOptions, ... }:

let
  inherit (lib)
    types;
in
{
  options = mkCabalSettingOptions {
    inherit config;
    name = "jailbreak";
    type = types.bool;
    description = ''
      Remove version bounds from this package's cabal file.
    '';
    impl = enable: with pkgs.haskell.lib.compose;
      if enable then doJailbreak else dontJailbreak;
  };
}
