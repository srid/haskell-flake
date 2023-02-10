{ config, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    ;
in
mkTransposedPerSystemModule {
  name = "haskellFlakeProjectModules";
  option = mkOption {
    type = types.lazyAttrsOf types.deferredModule;
    default = { };
    description = ''
    '';
  };
  file = ./project-module.nix;
}
