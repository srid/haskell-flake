# Definition of the `haskellProjects.${name}` submodule's `config`
project@{ lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;

  packageOptions = { config, ... }: {
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
  };

  packageSubmodule = types.deferredModuleWith {
    staticModules = [
      packageOptions
    ];
  };

  # Merge the list of attrset of modules.
  mergeModuleAttrs = attrs:
    lib.zipAttrsWith (k: vs: { imports = vs; }) attrs;

in
{
  options = {
    packages = lib.mkOption {
      type = types.lazyAttrsOf packageSubmodule;
      apply = packages:
        let
          packages' =
            # Merge user-provided 'packages' with 'defaults.packages'. 
            #
            # Note that the user can override the latter too if they wish.
            mergeModuleAttrs
              [ project.config.defaults.packages packages ];
        in
        lib.mapAttrs
          (k: v:
            (lib.evalModules {
              modules = [ v ];
              specialArgs = { inherit pkgs; };
            }).config
          )
          packages';
      description = ''
        Set of local packages in the project repository.

        If you have a `cabal.project` file (under `projectRoot`), those packages
        are automatically discovered. Otherwise, the top-level .cabal file is
        used to discover the only local package.
        
        haskell-flake currently supports a limited range of syntax for
        `cabal.project`. Specifically it requires an explicit list of package
        directories under the "packages" option.
      '';
    };
  };
}
