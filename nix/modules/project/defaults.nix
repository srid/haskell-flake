# A module representing the default values used internally by haskell-flake.
{ lib, pkgs, config, ... }:
let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo;
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
        let
          haskell-parsers = import ../../haskell-parsers {
            inherit pkgs lib;
            throwError = msg: config.log.throwError ''
              A default value for `packages` cannot be auto-determined:

                ${msg}

              Please specify the `packages` option manually or change your project configuration (cabal.project).
            '';
          };
        in
        lib.pipe config.projectRoot [
          haskell-parsers.findPackagesInCabalProject
          (lib.mapAttrs (_: path: {
            # The rest of the module options are not defined, because we'll use
            # the submodule defaults.
            source = path;
          }))
        ];
      apply = x:
        config.log.traceDebug "defaults.packages = ${builtins.toJSON x}" x;
      defaultText = lib.literalMD ''
        If you have a `cabal.project` file (under `projectRoot`), those packages
        are automatically discovered. Otherwise, the top-level .cabal file is
        used to discover the only local package.
        
        haskell-flake currently supports a limited range of syntax for
        `cabal.project`. Specifically it requires an explicit list of package
        directories under the "packages" option.
      '';
    };

    settings = mkOption {
      type = types.deferredModule;
      description = ''
        Sensible defaults for local packages
      '';
      default = { name, package, config, ... }: lib.optionalAttrs (package.local or false) {
        # Disabling haddock and profiling is mainly to speed up Nix builds.
        haddock = lib.mkDefault false; # Because, this is end-user software. No need for library docs.
        libraryProfiling = lib.mkDefault false; # Avoid double-compilation.
        separateBinOutput = lib.mkDefault (package.cabal.executables != [ ]); # Reduce closure size
      };
      defaultText = ''
        Settings suitable for end user software

        - Speed up builds by disabling haddock and library profiling.
        - Separate bin output (for reduced closure size when using `getBin` in apps)
      '';
    };

    projectModules.output = mkOption {
      type = types.deferredModule;
      description = ''
        A haskell-flake project module that exports the `packages` and
        `settings` options to the consuming flake. This enables the use of this
        flake's Haskell package as a dependency, re-using its overrides.
      '';
      default = {
        inherit (config)
          packages settings;
      };
    };
  };
}
