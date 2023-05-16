{ project, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;
in
{ config, ... }: {
  options = {
    root = mkOption {
      type = types.nullOr types.path;
      description = ''
        Path containing the Haskell package's `.cabal` file.
      '';
      default = null;
    };

    local = mkOption {
      type = types.bool;
      description = ''
        Whether this package is local to the flake.
      '';
      internal = true;
      readOnly = true;
      default =
        config.root != null &&
        lib.strings.hasPrefix "${project.config.projectRoot}" "${config.root}";
      defaultText = ''
        Computed automatically if package 'root' is under 'projectRoot'.
      '';
    };

    # cabal2nix stuff goes here.

    check = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Whether to run cabal tests as part of the nix build
      '';
      default = null;
    };

    haddock = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Whether to generate haddock documentation as part of the nix build
      '';
      default = null;
    };

    extraBuildDepends = mkOption {
      type = types.nullOr (types.listOf types.package);
      description = ''
        Extra build dependencies for the package.
      '';
      default = null;
    };

    apply = mkOption {
      type = types.functionTo types.package;
      internal = true;
      readOnly = true;
      description = ''
        A function that applies all the overrides in this module.
        
        `pkgs.haskell.lib.compose` is used to apply the override.
      '';
      default = with pkgs.haskell.lib.compose;
        lib.flip lib.pipe (
          lib.optional (config.check != null)
            (if config.check then doCheck else dontCheck)
          ++
          lib.optional (config.haddock != null)
            (if config.haddock then doHaddock else dontHaddock)
          ++
          lib.optional (config.extraBuildDepends != null && config.extraBuildDepends != [ ])
            (addBuildDepends config.extraBuildDepends)
        );
    };
  };
}
