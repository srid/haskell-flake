# Definition of the `haskellProjects.${name}` submodule's `config`
project@{ lib, pkgs, ... }:
let
  inherit (lib)
    types;

  packageSubmodule = import ./package.nix { inherit lib pkgs; };

  # Merge the list of attrset of modules.
  mergeModuleAttrs = attrs:
    lib.zipAttrsWith
      (k: vs:
        { imports = vs; })
      attrs;
in
{
  options = {
    packages = lib.mkOption {
      type = types.lazyAttrsOf types.deferredModule;
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
              modules = [ packageSubmodule v ];
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
