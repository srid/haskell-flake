{ config, pkgs, lib, mkCabalSettingOptions, ... }:

let
  inherit (lib)
    types;
in
{
  options = mkCabalSettingOptions {
    inherit config;
    name = "check";
    type = types.bool;
    description = ''
      Whether to run cabal tests as part of the nix build
    '';
    impl = enable: with pkgs.haskell.lib.compose;
      if enable then doCheck else dontCheck;
  };
}
