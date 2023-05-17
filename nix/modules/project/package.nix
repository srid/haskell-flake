{ project, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;
in
{ config, ... }: {
  options = {
    # TODO: Rename this to 'source'?
    root = mkOption {
      type = types.nullOr (types.either types.path types.string);
      description = ''
        Path containing the Haskell package's `.cabal` file.

        Or version string for a version in Hackage.
      '';
      default = null;
    };

    localTo = mkOption {
      type = types.functionTo types.bool;
      description = ''
        Whether this package is local to a projectRoot.
      '';
      internal = true;
      # FIXME: why can't we set this when using project-modules.nix?
      # readOnly = true;
      default = projectRoot:
        let
          t = x: builtins.trace x x;
        in
        config.root != null &&
        lib.strings.hasPrefix (t "${projectRoot}") "${config.root}";
      defaultText = ''
        Computed automatically if package 'root' is under 'projectRoot'.
      '';
    };

    # cabal2nix stuff goes here.
    settings = mkOption {
      default = { };
      type = types.submoduleWith {
        specialArgs = {
          inherit pkgs lib;
        } // (import ./settings/lib.nix {
          inherit lib;
          config = config.settings;
        });
        modules = [{
          imports = [
            ./settings
          ];
        }];
      };
    };

    applySettings = mkOption {
      type = types.functionTo (types.functionTo (types.functionTo types.package));
      internal = true;
      # FIXME: why can't we set this when using project-modules.nix?
      # readOnly = true;
      description = ''
        A function that applies all the 'settings' in this module.
      '';
      default = self: super: p:
        let
          implList = lib.pipe config.settings.impl [
            lib.attrValues
            (lib.concatMap (impl: impl self super))
          ];
        in
        lib.pipe p implList;
    };
  };
}
