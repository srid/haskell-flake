{ withSystem, ... }:

{
  config = {
    haskellFlakeProjectModules =
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
  };
}
