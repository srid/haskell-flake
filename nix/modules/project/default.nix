# Definition of the `haskellProjects.${name}` submodule's `config`
{ self, name, config, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    raw;
in
{
  imports = [
    ./defaults.nix
    ./packages
    ./settings
    ./devshell.nix
    ./outputs.nix
  ];
  options = {
    projectRoot = mkOption {
      type = types.path;
      description = ''
        Path to the root of the project directory.

        Chaning this affects certain functionality, like where to
        look for the 'cabal.project' file.
      '';
      default = self;
      defaultText = "Top-level directory of the flake";
    };
    projectFlakeName = mkOption {
      type = types.nullOr types.str;
      description = ''
        A descriptive name for the flake in which this project resides.

        If unspecified, the Nix store path's basename will be used.
      '';
      default = null;
      apply = cls:
        if cls == null
        then builtins.baseNameOf config.projectRoot
        else cls;
    };
    log = mkOption {
      type = types.lazyAttrsOf (types.functionTo types.raw);
      default = import ../../logging.nix {
        name = config.projectFlakeName + "#haskellProjects." + name;
      };
      internal = true;
      readOnly = true;
      description = ''
        Internal logging module
      '';
    };
    basePackages = mkOption {
      type = types.lazyAttrsOf raw;
      description = ''
        Which Haskell package set / compiler to use.

        You can effectively select the GHC version here. 
                  
        To get the appropriate value, run:

            nix-env -f "<nixpkgs>" -qaP -A haskell.compiler

        And then, use that in `pkgs.haskell.packages.ghc<version>`
      '';
      example = "pkgs.haskell.packages.ghc924";
      default = pkgs.haskellPackages;
      defaultText = lib.literalExpression "pkgs.haskellPackages";
    };
    otherOverlays = lib.mkOption {
      type = types.listOf (import ../../types/haskell-overlay-type.nix { inherit lib; });
      description = ''
        Extra overlays to apply.
      '';
    };
    autoWire =
      let
        outputTypes = [ "packages" "checks" "apps" "devShells" ];
      in
      mkOption {
        type = types.listOf (types.enum outputTypes);
        description = ''
          List of flake output types to autowire.

          Using an empty list will disable autowiring entirely,
          enabling you to manually wire them using
          `config.haskellProjects.<name>.outputs`.
        '';
        default = outputTypes;
      };
  };
}

