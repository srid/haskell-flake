{ lib, withSystem, ... }:

let
  inherit (lib)
    mkOption
    types;
in
{
  options.flake = mkOption {
    type = types.submoduleWith {
      modules = [{
        options.haskellFlakeProjectModules = mkOption
          {
            type = types.lazyAttrsOf types.deferredModule;
            description = ''
              A lazy attrset of `haskellProjects.<name>` modules that can be
              imported in other flakes.
            '';
            defaultText = ''
              Package and dependency information for this project exposed for reuse
              in another flake, when using this project as a Haskell dependency.

              Typically the consumer of this flake will want to use one of the
              following modules:

                - output: provides both local package and dependency overrides.
                - local: provides only local package overrides (ignores dependency
                  overrides in this flake)

              These default modules are always available.
            '';
            default = { }; # Set in config (see ./default-project-modules.nix)
          };

        config.haskellFlakeProjectModules =
          let
            defaults = rec {
              # The 'output' module provides both local package and dependency
              # overrides.
              output = {
                imports = [ input local ];
              };
              # The 'local' module provides only local package overrides.
              local = { pkgs, lib, ... }: withSystem pkgs.system ({ config, ... }: {
                source-overrides =
                  lib.mapAttrs (_: v: v.root)
                    config.haskellProjects.default.packages;
              });
              # The 'input' module contains only dependency overrides.
              input = { pkgs, ... }: withSystem pkgs.system ({ config, ... }: {
                inherit (config.haskellProjects.default)
                  source-overrides overrides;
              });
            };
          in
          defaults;
      }];
    };
  };
}
