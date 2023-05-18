{ project, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;
  # TODO: DRY
  isPathUnderNixStore = path: builtins.hasContext (builtins.toString path);
  haskellSourceType = lib.mkOptionType {
    name = "haskellSource";
    description = ''
      Path to Haskell package source, or version from Hackage.
    '';
    check = path:
      isPathUnderNixStore path || builtins.isString path;
    merge = lib.mergeOneOption;
  };
in
{ name, config, ... }: {
  options = {
    # TODO: Rename this to 'source'?
    root = mkOption {
      type = types.nullOr haskellSourceType;
      description = ''
        Path containing the Haskell package's `.cabal` file.

        Or version string for a version in Hackage.
      '';
      default = null;
    };

    cabal.executables = mkOption {
      type = types.nullOr (types.listOf types.string);
      description = ''
        List of executable names found in the cabal file of the package.
        
        The value is null if 'root' option is Hackage version.
      '';
      default =
        let
          haskell-parsers = import ../../haskell-parsers {
            inherit pkgs lib;
            throwError = msg: config.log.throwError ''
              Unable to determine executable names for package ${name}:

                ${msg}
            '';
          };
        in
        if isPathUnderNixStore config.root
        then haskell-parsers.getCabalExecutables config.root
        else null; # cfg.root is Hackage version; nothing to do.
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
        config.root != null &&
        isPathUnderNixStore config.root &&
        lib.strings.hasPrefix "${projectRoot}" "${config.root}";
      defaultText = ''
        Computed automatically if package 'root' is under 'projectRoot'.
      '';
    };

    # cabal2nix stuff goes here.
    settings = mkOption {
      default = { };
      description = ''
        Overrides for an individual Haskell package.
      '';
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
