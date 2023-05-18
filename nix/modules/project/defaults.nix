# A module representing the default values used internally by haskell-flake.
{ name, lib, pkgs, config, ... }:
let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo;

  haskell-parsers = import ../../haskell-parsers {
    inherit pkgs lib;
    throwError = msg: config.log.throwError ''
      A default value for `packages` cannot be auto-determined:

        ${msg}

      Please specify the `packages` option manually or change your project configuration (cabal.project).
    '';
  };
in
{
  options.defaults = {
    devShell.tools = mkOption {
      type = functionTo (types.attrsOf (types.nullOr types.package));
      description = ''Build tools always included in devShell'';
      default = hp: with hp; {
        inherit
          cabal-install
          haskell-language-server
          ghcid
          hlint;
      };
    };
    packages = mkOption {
      type = types.lazyAttrsOf types.deferredModule;
      description = ''Local packages scanned from projectRoot'';
      default =
        lib.pipe config.projectRoot [
          haskell-parsers.findPackagesInCabalProject
          (lib.mapAttrs (_: path: { root = path; }))
          (x: config.log.traceDebug "config.haskellProjects.${name}.defaults.packages = ${builtins.toJSON x}" x)
        ];
      defaultText = lib.literalMD ''
        Scanned from `projectRoot`.
      '';
    };
  };
}
