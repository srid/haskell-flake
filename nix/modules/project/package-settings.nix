{ config, pkgs, lib, ... }:
let
  inherit (lib)
    mkOption
    types;

  # Overrides for package named 'name'
  packageSettingsSubmodule = types.submodule ({ name, ... }: {
    options = {
      source = mkOption {
        type = types.nullOr (types.either types.path types.string);
        default = null;
      };
      overrides = mkOption {
        type = types.listOf (types.functionTo types.package);
        default = [ ];
      };
    };
  });
in
{
  options = {
    packageSettings = mkOption {
      type = types.listOf (types.attrsOf packageSettingsSubmodule);
      default = [ ];
    };
    packageSettingsOverlay = mkOption {
      type = pkgs.callPackage ../../types/haskell-overlay-type.nix { };
      internal = true;
      readOnly = true;
    };
  };

  config = {
    packageSettingsOverlay =
      lib.composeManyExtensions
        (lib.forEach config.packageSettings (settings: self: super:
          lib.flip lib.mapAttrs settings
            (name: settings:
              let
                drv =
                  if settings.source == null
                  then super.${name}
                  else if builtins.isPath settings.source
                  then self.callCabal2nix name settings.source { }
                  else self.callHackage name settings.source { };
              in
              lib.pipe drv settings.overrides
            )
        ));
  };
}
