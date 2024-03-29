# A module representing the default values used internally by haskell-flake.
{ name, lib, pkgs, config, ... }:
let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo;
in
{
  options.defaults = {
    enable = mkOption {
      type = types.bool;
      description = ''
        Whether to enable haskell-flake's default settings for this project.
      '';
      default = true;
    };

    devShell.tools = mkOption {
      type = functionTo (types.lazyAttrsOf (types.nullOr types.package));
      description = ''Build tools always included in devShell'';
      default = hp: with hp; lib.optionalAttrs config.defaults.enable {
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
          localPackages = lib.pipe config.projectRoot [
            haskell-parsers.findPackagesInCabalProject
            (x: config.log.traceDebug "${name}.findPackagesInCabalProject = ${builtins.toJSON x}" x)
            (lib.mapAttrs (_: path: {
              # The rest of the module options are not defined, because we'll use
              # the submodule defaults.
              source = path;
            }))
          ];
        in
        lib.optionalAttrs config.defaults.enable localPackages;
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

    settings.default = mkOption {
      type = types.deferredModule;
      description = ''
        Default settings for all packages in `packages` option.
      '';
      defaultText = ''
        Speed up builds by disabling haddock and library profiling.

        This uses `local.toDefinedProject` option to determine which packages to
        override. Thus, it applies to both local packages as well as
        transitively imported packags that are local to that flake (managed by
        haskell-flake). The goal being to use the same configuration
        consistently for all packages using haskell-flake.
      '';
      default =
        let
          globalSettings = {
            # We disable this by default because it causes breakage.
            # See https://github.com/srid/haskell-flake/pull/253
            buildFromSdist = lib.mkDefault true;
          };
          localSettings = { name, package, config, ... }:
            lib.optionalAttrs (package.local.toDefinedProject or false) {
              # Disabling haddock and profiling is mainly to speed up Nix builds.
              haddock = lib.mkDefault false; # Because, this is end-user software. No need for library docs.
              libraryProfiling = lib.mkDefault false; # Avoid double-compilation.
            };
        in
        if config.defaults.enable then {
          imports = [
            globalSettings
            localSettings
          ];
        } else { };
    };

    projectModules.output = mkOption {
      type = types.deferredModule;
      description = ''
        A haskell-flake project module that exports the `packages` and
        `settings` options to the consuming flake. This enables the use of this
        flake's Haskell package as a dependency, re-using its overrides.
      '';
      default = lib.optionalAttrs config.defaults.enable {
        inherit (config)
          packages settings;
      };
      defaultText = lib.literalMD ''a generated module'';
    };
  };
}
