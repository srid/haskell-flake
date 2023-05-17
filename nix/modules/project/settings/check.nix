{ pkgs, lib, mkCabalSettingOptions, ... }:

let
  inherit (lib)
    types;
in
{
  options = mkCabalSettingOptions {
    name = "check";
    type = types.bool;
    description = ''
      Whether to run cabal tests as part of the nix build
    '';
    impl = check: with pkgs.haskell.lib.compose;
      if check then doCheck else dontCheck;
  };
}
