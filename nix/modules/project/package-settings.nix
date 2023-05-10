{ config, pkgs, lib, ... }:
let
  inherit (lib)
    mkOption
    types;

  # Overrides for package named 'name'
  packageSettingsSubmodule = types.submoduleWith {
    specialArgs = { };
    modules = [
      ({ name, ... }: {
        options = {
          source = mkOption {
            type = types.nullOr (types.either types.path types.string);
            default = null;
          };
          overrides = mkOption {
            type =
              let t = types.listOf (types.functionTo types.package);
              in types.either t (types.functionTo (types.functionTo t));
            default = [ ];
          };
        };
      })
    ];
  };
in
{
  options = {
    packageSettings = mkOption {
      type = types.listOf (types.lazyAttrsOf packageSettingsSubmodule);
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
                overrides =
                  if builtins.isList settings.overrides
                  then settings.overrides
                  else settings.overrides self super;
              in
              lib.pipe drv overrides
            )
        ));
  };
}
