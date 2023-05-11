{ pkgs, lib, withSystem, ... }:

let
  inherit (lib)
    mkOption
    types;
  haskellOverlayType = pkgs.callPackage ../types/haskell-overlay-type.nix { };
  haskellOverlayTypeDummy =
    types.functionTo
      (types.functionTo
        (types.lazyAttrsOf types.raw));
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
          local = self: super:
            withSystem super.ghc.system ({ config, ... }:
              # The 'local' overlay provides only local package overrides.
              lib.mapAttrs
                (name: v:
                  # TODO: use sdist etc all like build-haskell-packages.nix
                  self.callCabal2nix name v.root { })
                config.haskellProjects.default.packages
            );
          input = self: super:
            withSystem super.ghc.system ({ config, ... }:
              config.haskellProjects.default.packageSettingsOverlay self super
            );
        };
      }];
    };
  };
}
