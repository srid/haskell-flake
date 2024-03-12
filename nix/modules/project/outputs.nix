# haskellProjects.<name>.outputs module.
{ config, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;

  appType = import ../../types/app-type.nix { inherit pkgs lib; };

  outputsSubmodule = types.submodule {
    options = {
      finalOverlay = mkOption {
        type = types.raw;
        readOnly = true;
        internal = true;
      };
      finalPackages = mkOption {
        # This must be raw because the Haskell package set also contains functions.
        type = types.lazyAttrsOf types.raw;
        readOnly = true;
        description = ''
          The final Haskell package set including local packages and any
          overrides, on top of `basePackages`.
        '';
      };
      packages = mkOption {
        type = types.lazyAttrsOf packageInfoSubmodule;
        readOnly = true;
        description = ''
          Package information for all local packages. Contains the following keys:

          - `package`: The Haskell package derivation
          - `exes`: Attrset of executables found in the .cabal file
        '';
      };
      apps = mkOption {
        type = types.lazyAttrsOf appType;
        readOnly = true;
        description = ''
          Flake apps for each Cabal executable in the project.
        '';
      };
    };
  };

  packageInfoSubmodule = types.submodule {
    options = {
      package = mkOption {
        type = types.package;
        description = ''
          The local package derivation.
        '';
      };
      exes = mkOption {
        type = types.lazyAttrsOf appType;
        description = ''
          Attrset of executables from `.cabal` file.  

          If the associated Haskell project has a separate bin output
          (cf. `enableSeparateBinOutput`), then this exe will refer
          only to the bin output.

          NOTE: Evaluating up to this option will involve IFD.
        '';
      };
    };
  };
in
{
  options = {
    outputs = mkOption {
      type = outputsSubmodule;
      description = ''
        The flake outputs generated for this project.

        This is an internal option, not meant to be set by the user.
      '';
    };
  };
  config =
    let
      # Subet of config.packages that are local to the project.
      localPackages =
        lib.filterAttrs (_: cfg: cfg.local.toCurrentProject) config.packages;

      finalOverlay = lib.composeManyExtensions [
        config.packagesOverlay
        config.settingsOverlay
      ];

      finalPackages = config.basePackages.extend finalOverlay;

      buildPackageInfo = name: value: {
        package = finalPackages.${name};
        exes =
          lib.listToAttrs
            (map
              (exe:
                lib.nameValuePair exe {
                  program = "${lib.getBin finalPackages.${name}}/bin/${exe}";
                }
              )
              value.cabal.executables
            );
      };

    in
    {
      outputs = {
        inherit finalOverlay finalPackages;

        packages = lib.mapAttrs buildPackageInfo localPackages;

        apps =
          lib.mkMerge
            (lib.mapAttrsToList (_: packageInfo: packageInfo.exes) config.outputs.packages);
      };
    };
}

