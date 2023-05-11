{ pkgs, lib, withSystem, ... }:

let
  inherit (lib)
    mkOption
    types;
  haskellOverlayType = pkgs.callPackage ../types/haskell-overlay-type.nix { };
  haskellOverlayTypeDummy =
    types.functionTo
      (types.functionTo
        (types.lazyAttrsOf types.package));
in
{
  options.flake = mkOption {
    type = types.submoduleWith {
      modules = [{
        options.haskellFlakeProjectModules = mkOption {
          type = types.lazyAttrsOf types.deferredModule;
          description = ''
            A lazy attrset of `haskellProjects.<name>` modules that can be
            imported in other flakes.
          '';
          default = { };
        };
        options.haskellFlakeProjectOverlays = mkOption {
          type = types.lazyAttrsOf haskellOverlayTypeDummy;
        };

        config.haskellFlakeProjectOverlays = rec {
          output = lib.composeManyExtensions [
            local
            input
          ];
          # The 'local' overlay provides only local package overrides.
          local = self: super:
            withSystem super.ghc.system ({ config, ... }:
              config.haskellProjects.default.outputs.localPackagesOverlay self super
            );
          input = self: super:
            withSystem super.ghc.system ({ config, ... }:
              config.haskellProjects.default.outputs.packageSettingsOverlay self super
            );
        };
      }];
    };
  };
}
