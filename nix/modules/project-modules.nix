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
            defaultText = lib.literalMD ''
              Package and dependency information for this project exposed for reuse
              in another flake, when using this project as a Haskell dependency.

              A 'default' module is provided that exports the `packages` and
              `settings` options to the consuming flake, in effect to use this
              flake's Haskell package as a dependency re-using its overrides.
            '';
            default = { };
          };

        config.haskellFlakeProjectModules =
          let
            defaults = {
              output = { pkgs, lib, ... }: withSystem pkgs.system ({ config, ... }: {
                inherit (config.haskellProjects.default)
                  packages settings;
              });
            };
          in
          defaults;
      }];
    };
  };
}
