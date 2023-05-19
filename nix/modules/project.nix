# Definition of the `haskellProjects.${name}` submodule's `config`
{ self, config, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    raw;

  haskellOverlayType = import ../types/haskell-overlay-type.nix { inherit lib; };
in
{
  imports = [
    ./project/defaults.nix
    ./project/packages.nix
    ./project/devshell.nix
    ./project/outputs.nix
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
    debug = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable verbose trace output from haskell-flake.

        Useful for debugging.
      '';
    };
    log = mkOption {
      type = types.attrsOf (types.functionTo types.raw);
      default = import ../logging.nix { inherit (config) debug; };
      internal = true;
      readOnly = true;
      description = ''
        Internal logging module
      '';
    };
    basePackages = mkOption {
      type = types.attrsOf raw;
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
    source-overrides = mkOption {
      type = types.attrsOf (types.oneOf [ types.path types.str ]);
      description = ''
        Source overrides for Haskell packages

        You can either assign a path to the source, or Hackage
        version string.
      '';
      default = { };
    };
    overrides = mkOption {
      type = haskellOverlayType;
      description = ''
        Cabal package overrides for this Haskell project
                
        For handy functions, see 
        <https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix>

        **WARNING**: When using `imports`, multiple overlays
        will be merged using `lib.composeManyExtensions`.
        However the order the overlays are applied can be
        arbitrary (albeit deterministic, based on module system
        implementation).  Thus, the use of `overrides` via
        `imports` is not officiallly supported. If you'd like
        to see proper support, add your thumbs up to
        <https://github.com/NixOS/nixpkgs/issues/215486>.
      '';
      default = self: super: { };
      defaultText = lib.literalExpression "self: super: { }";
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

