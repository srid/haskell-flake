{ pkgs, lib, mkCabalSettingOptions, ... }:

let
  inherit (lib)
    types;
in
{
  options = mkCabalSettingOptions {
    name = "libraryProfiling";
    type = types.bool;
    description = ''
      Build the library for profiling by default.
    '';
    impl = enable: with pkgs.haskell.lib.compose;
      if enable then enableLibraryProfiling else disableLibraryProfiling;
  };
}
