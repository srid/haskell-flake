# Definition of the `haskellProjects.${name}` submodule's `config`
{ name, config, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;

  haskell-parsers = import ../../haskell-parsers {
    inherit pkgs lib;
    throwError = msg: config.log.throwError ''
      A default value for `packages` cannot be auto-determined:

        ${msg}

      Please specify the `packages` option manually or change your project configuration (cabal.project).
    '';
  };

  packageSubmodule = with types; submoduleWith {
    modules = [
      ({ config, ... }: {
        options = {
          root = mkOption {
            type = types.nullOr path;
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
              );
          };
        };
      })
    ];
  };

in
{
  options = {
    packages = mkOption {
      type = types.lazyAttrsOf packageSubmodule;
      description = ''
        Set of local packages in the project repository.

        If you have a `cabal.project` file (under `projectRoot`), those packages
        are automatically discovered. Otherwise, the top-level .cabal file is
        used to discover the only local package.
        
        haskell-flake currently supports a limited range of syntax for
        `cabal.project`. Specifically it requires an explicit list of package
        directories under the "packages" option.
      '';
      default =
        lib.pipe config.projectRoot [
          haskell-parsers.findPackagesInCabalProject
          (x: config.log.traceDebug "config.haskellProjects.${name}.packages = ${builtins.toJSON x}" x)

          (lib.mapAttrs (_: path: { root = path; }))
        ];
      defaultText = lib.literalMD "autodiscovered by reading `self` files.";
    };
  };
}
