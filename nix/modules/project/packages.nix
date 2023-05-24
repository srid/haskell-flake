# Definition of the `haskellProjects.${name}` submodule's `config`
project@{ name, lib, pkgs, ... }:
let
  inherit (lib)
    types;

  packageSubmodule = import ./package.nix { inherit project lib pkgs; };

  # Merge the list of attrset of modules.
  mergeModuleAttrs =
    lib.zipAttrsWith (k: vs: { imports = vs; });

  tracePackages = k: x:
    project.config.log.traceDebug "${k} ${builtins.toJSON x}" x;
in
{
  options = {
    packages = lib.mkOption {
      type = types.lazyAttrsOf types.deferredModule;
      default = { };
      apply = packages:
        let
          packages' =
            # Merge user-provided 'packages' with 'defaults.packages'. 
            #
            # Note that the user can override the latter too if they wish.
            mergeModuleAttrs
              [ project.config.defaults.packages packages ];
        in
        tracePackages "${name}.packages:apply" (
          lib.mapAttrs
            (name: v:
              (lib.evalModules {
                modules = [ packageSubmodule v ];
                specialArgs = { inherit name pkgs; };
              }).config
            )
            packages');

      description = ''
        Additional packages to add to `basePackages`.

        Local packages are added automatically (see `config.defaults.packages`):
      '';
    };
  };
}
