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
        type = types.attrsOf types.raw;
        readOnly = true;
        description = ''
          The final Haskell package set including local packages and any
          overrides, on top of `basePackages`.
        '';
      };
      packages = mkOption {
        type = types.attrsOf packageInfoSubmodule;
        readOnly = true;
        description = ''
          Package information for all local packages. Contains the following keys:

          - `package`: The Haskell package derivation
          - `exes`: Attrset of executables found in the .cabal file
        '';
      };
      apps = mkOption {
        type = types.attrsOf appType;
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
        type = types.attrsOf appType;
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
      inherit (config.outputs) finalPackages;

      # Subet of config.packages that are local to the project.
      localPackages =
        lib.filterAttrs (_: cfg: cfg.local) config.packages;

      packagesOverlays = {
        # Overlay for `config.packages`
        sources = self: super:
          let
            isPathUnderNixStore = path: builtins.hasContext (builtins.toString path);
            build-haskell-package = import ../../build-haskell-package.nix {
              inherit pkgs lib self super;
              inherit (config) log;
            };
            getOrMkPackage = name: cfg:
              if isPathUnderNixStore cfg.source
              then
                config.log.traceDebug "${name}.callCabal2nix ${cfg.source}"
                  (build-haskell-package name cfg.source)
              else
                config.log.traceDebug "${name}.callHackage ${cfg.source}"
                  (self.callHackage name cfg.source { });
          in
          lib.mapAttrs getOrMkPackage config.packages;

        # Overlay for `config.settings`
        settings = self: super:
          let
            applySettingsFor = name: cfg:
              lib.pipe super.${name} (
                # TODO: Do we care about the *order* of overrides?
                # Might be relevant for the 'custom' option.
                lib.concatMap
                  (impl: impl)
                  (lib.attrValues (cfg self super).impl)
              );
          in
          lib.mapAttrs applySettingsFor 
            (config.evalSettings config.settings self super);
      };

      finalOverlay = lib.composeManyExtensions [
        packagesOverlays.sources
        packagesOverlays.settings
      ];

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
        inherit finalOverlay;

        finalPackages = config.basePackages.extend finalOverlay;

        packages = lib.mapAttrs buildPackageInfo localPackages;

        apps =
          lib.mkMerge
            (lib.mapAttrsToList (_: packageInfo: packageInfo.exes) config.outputs.packages);
      };
    };
}

