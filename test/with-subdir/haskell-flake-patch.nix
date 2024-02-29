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
      haskellProjectTests = mkOption {
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
                expect = lib.mkOption {
                  type = types.raw;
                  description = "Test expectation";
                };
              };
            }
          ];
        });
      };
    };

    config = {
      haskellProjects = lib.flip lib.mapAttrs config.haskellProjectTests (name: cfg: {
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

      checks = lib.flip lib.mapAttrs config.haskellProjectTests (name: cfg:
        pkgs.runCommandNoCC "haskell-flake-patch-test-${name}"
          {
            EXPECT = builtins.toJSON cfg.expect;
          }
          ''touch $out''
      );
    };
  });

}
