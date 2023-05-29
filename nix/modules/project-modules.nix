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

              The 'output' module of the default project is included by default,
              returning `defaults.projectModules.output`.
            '';
            default = { };
          };

        config.haskellFlakeProjectModules = {
          output = { pkgs, lib, ... }: withSystem pkgs.system ({ config, ... }:
            config.haskellProjects."default".defaults.projectModules.output
          );
        };
      }];
    };
  };
}
