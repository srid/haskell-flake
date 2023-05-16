{ lib, pkgs, ... }:
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
