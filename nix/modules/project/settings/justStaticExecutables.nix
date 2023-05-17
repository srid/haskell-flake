{ pkgs, lib, mkCabalSettingOptions, ... }:

let
  inherit (lib)
    types;
in
{
  options = mkCabalSettingOptions {
    name = "justStaticExecutables";
    type = types.bool;
    description = ''
      Link executables statically against haskell libs to reduce closure size
    '';
    impl = enable: with pkgs.haskell.lib.compose;
      if enable then justStaticExecutables else x: x;
  };
}
