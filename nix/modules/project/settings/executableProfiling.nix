{ config, pkgs, lib, mkCabalSettingOptions, ... }:

let
  inherit (lib)
    types;
in
{
  options = mkCabalSettingOptions {
    inherit config;
    name = "executableProfiling";
    type = types.bool;
    description = ''
      Build the executable with profiling enabled.
    '';
    impl = enable: with pkgs.haskell.lib.compose;
      if enable then enableExecutableProfiling else disableExecutableProfiling;
  };
}
