# A convenient module for testing haskell-flake behaviour.
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
        description = ''
          Patch an existing `haskellProject` to run some checks. This module
          will create a flake check automatically.  
        '';
        default = { };
        type = types.lazyAttrsOf (types.submoduleWith {
          specialArgs = { inherit pkgs self; };
          modules = [
            {
              options = {
                from = lib.mkOption {
                  type = types.str;
                  default = "default";
                  description = ''
                    Which `haskellProjects.??` to patch.
                  '';
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
                  description = ''
                    Arbitrary expression to evaluate as part of the generated
                    flake check
                  '';
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
