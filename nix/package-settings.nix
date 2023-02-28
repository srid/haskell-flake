# A haskell-flake module providing a simpler interface to `overrides`. The
# config implementation simply expands to `overrides`.
{ config, pkgs, lib, ... }:

{
  options = {
    packageSettings = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.submodule {
        options = {
          input = lib.mkOption {
            default = { };
            type = lib.types.deferredModuleWith {
              staticModules = [
                ({ lib, self, super, ... }: {
                  # TODO: What is the best way to do enum type here?
                  options = {
                    path = lib.mkOption {
                      type = lib.types.nullOr lib.types.path;
                      default = null;
                      description = "Source path";
                    };
                    drv = lib.mkOption {
                      type = lib.types.nullOr lib.types.package;
                      default = null;
                      description = "Cabal derivation";
                    };
                    hackageVersion = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "Hackage version";
                    };
                  };
                })
              ];
            };
            description = "Source or derivation to use for this package";
          };
          overrides = lib.mkOption {
            default = { };
            type = lib.types.deferredModuleWith {
              staticModules = [
                ({ lib, old, ... }: {
                  options = {
                    # TODO: Write the rest of the options
                    doCheck = lib.mkOption {
                      type = lib.types.nullOr lib.types.bool;
                      default = null;
                      description = "Whether to run tests";
                    };
                    jailbreak = lib.mkOption {
                      type = lib.types.nullOr lib.types.bool;
                      default = null;
                      description = "Whether to disable version bounds";
                    };
                    doHaddock = lib.mkOption {
                      type = lib.types.nullOr lib.types.bool;
                      default = null;
                      description = "Whether to generate documentation";
                    };
                    patches = lib.mkOption {
                      type = lib.types.nullOr (lib.types.listOf lib.types.path);
                      default = null;
                      description = "Patches to apply";
                    };
                  };
                })
              ];
            };
            description = "Cabal overrides";
          };
        };
      });
      default = { };
      description = "Package settings";
    };
  };
  config = {
    overrides = self: super:
      lib.mapAttrs
        (name: settings:
          let
            evalModSimple = mod: specialArgs:
              (lib.evalModules { modules = [ mod ]; inherit specialArgs; }).config;
          in
          let
            input = evalModSimple settings.input { inherit lib self super; };
            drv =
              # NOTE: See the corresponding TODO on the option type.
              if input.drv != null
              then input.drv
              else if input.hackageVersion != null
              then self.callHackage name input.hackageVersion { }
              else if input.path != null
              then self.callCabal2nix name input.path { }
              else super.${name};
            overrideCabal =
              pkgs.haskell.lib.compose.overrideCabal
                (old:
                  let mod = evalModSimple settings.overrides { inherit lib old; };
                  in lib.filterAttrs (n: v: v != null) mod
                );
          in
          overrideCabal drv
        )
        config.packageSettings;
  };
}
