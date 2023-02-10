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
      An attrset of `haskellProjects.<name>` modules that can be imported in
      other flakes.
    '';
  };
  file = ./project-module.nix;
}
