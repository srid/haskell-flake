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
      haskellProjects = mkOption {
        description = "Haskell projects";
        type = types.attrsOf (types.submoduleWith {
          specialArgs = { inherit pkgs self; };
          modules = [
            ./project.nix
          ];
        });
      };
    };

    config =
      let
        # Like mapAttrs, but merges the values (also attrsets) of the resulting attrset.
        mergeMapAttrs = f: attrs: lib.mkMerge (lib.mapAttrsToList f attrs);
        mapKeys = f: lib.mapAttrs' (n: v: { name = f n; value = v; });

        contains = k: lib.any (x: x == k);

        # Prefix value with the project name (unless
        # project is named `default`)
        prefixUnlessDefault = projectName: value:
          if projectName == "default"
          then value
          else "${projectName}-${value}";
      in
      {
        packages =
          mergeMapAttrs
            (name: project:
              let
                packages = lib.mapAttrs (_: info: info.package) project.outputs.packages;
              in
              lib.optionalAttrs (contains "packages" project.autoWire)
                (mapKeys (prefixUnlessDefault name) packages))
            config.haskellProjects;
        devShells =
          mergeMapAttrs
            (name: project:
              lib.optionalAttrs (contains "devShells" project.autoWire && project.devShell.enable) {
                "${name}" = project.outputs.devShell;
              })
            config.haskellProjects;
        checks =
          mergeMapAttrs
            (name: project:
              lib.optionalAttrs (contains "checks" project.autoWire)
                project.outputs.checks
            )
            config.haskellProjects;
        apps =
          mergeMapAttrs
            (name: project:
              lib.optionalAttrs (contains "apps" project.autoWire)
                (mapKeys (prefixUnlessDefault name) project.outputs.apps)
            )
            config.haskellProjects;
      };
  });
}


