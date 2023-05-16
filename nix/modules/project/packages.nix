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
in
{
  options = {
    packages =
      import ./package.nix {
        inherit lib pkgs;
        description = ''
          Set of local packages in the project repository.

          If you have a `cabal.project` file (under `projectRoot`), those packages
          are automatically discovered. Otherwise, the top-level .cabal file is
          used to discover the only local package.
        
          haskell-flake currently supports a limited range of syntax for
          `cabal.project`. Specifically it requires an explicit list of package
          directories under the "packages" option.
        '';
        lib.pipe config.projectRoot [
          haskell-parsers.findPackagesInCabalProject
          (x: config.log.traceDebug "config.haskellProjects.${name}.packages = ${builtins.toJSON x}" x)

          (lib.mapAttrs (_: path: { root = path; }))
        ];
      defaultText = lib.literalMD "autodiscovered by reading `self` files.";
      };
  };
}
