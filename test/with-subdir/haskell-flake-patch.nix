{ self, lib, flake-parts-lib, ... }:

let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    mkOption
    types;
in
{
  options.perSystem = mkPerSystemOption ({ config, self', pkgs, ... }: {
    options = {
      haskellProjectsPatched = mkOption {
        type = types.attrsOf (types.submoduleWith {
          specialArgs = { inherit pkgs self; };
          modules = [
            {
              options = {
                from = lib.mkOption {
                  type = types.str;
                  default = "default";
                };
                patches = lib.mkOption {
                  type = types.listOf (types.either types.path types.str);
                  description = ''
                    List of patches to apply to the project root.

                    Each patch can be a path to the diff file, or inline patch string.
                  '';
                };
              };
            }
          ];
        });
      };
    };

    config.haskellProjects = lib.flip lib.mapAttrs config.haskellProjectsPatched (name: cfg: {
      projectRoot = pkgs.applyPatches {
        name = "haskellProject-patched-${name}";
        src = config.haskellProjects.${cfg.from}.projectRoot;
        patches = lib.flip builtins.map cfg.patches (patch:
          if types.path.check patch then patch else
          pkgs.writeTextFile {
            name = "${name}.diff";
            text = patch;
          }
        );
      };
    });
  });

}
