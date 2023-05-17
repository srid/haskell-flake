{ pkgs, lib, mkCabalSettingOptions, ... }:

let
  inherit (lib)
    types;
  inherit (types)
    listOf;
in
{
  options = mkCabalSettingOptions {
    name = "extraBuildDepends";
    type = listOf types.package;
    description = ''
      Extra build dependencies for the package.
    '';
    impl = pkgs.haskell.lib.compose.addBuildDepends;
  };
}
