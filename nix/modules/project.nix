# Definition of the `haskellProjects.${name}` submodule's `config`
{ self, config, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    raw;

  appType = import ../types/app-type.nix { inherit pkgs lib; };
  haskellOverlayType = import ../types/haskell-overlay-type.nix { inherit lib; };

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
          - `executables`: Attrset of executables found in the .cabal file
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
          (cf. `enableSeparateBinOutput`), then this exes will refer
          only to the bin output.

          NOTE: Evaluating up to this option will involve IFD.
        '';
      };
    };
  };
in
{
  imports = [
    ./project/defaults.nix
    ./project/packages.nix
    ./project/devshell.nix
  ];
  options = {
    projectRoot = mkOption {
      type = types.path;
      description = ''
        Path to the root of the project directory.

        Chaning this affects certain functionality, like where to
        look for the 'cabal.project' file.
      '';
      default = self;
      defaultText = "Top-level directory of the flake";
    };
    debug = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable verbose trace output from haskell-flake.

        Useful for debugging.
      '';
    };
    log = mkOption {
      type = types.attrsOf (types.functionTo types.raw);
      default = import ../logging.nix { inherit (config) debug; };
      internal = true;
      readOnly = true;
      description = ''
        Internal logging module
      '';
    };
    basePackages = mkOption {
      type = types.attrsOf raw;
      description = ''
        Which Haskell package set / compiler to use.

        You can effectively select the GHC version here. 
                  
        To get the appropriate value, run:

            nix-env -f "<nixpkgs>" -qaP -A haskell.compiler

        And then, use that in `pkgs.haskell.packages.ghc<version>`
      '';
      example = "pkgs.haskell.packages.ghc924";
      default = pkgs.haskellPackages;
      defaultText = lib.literalExpression "pkgs.haskellPackages";
    };
    source-overrides = mkOption {
      type = types.attrsOf (types.oneOf [ types.path types.str ]);
      description = ''
        Source overrides for Haskell packages

        You can either assign a path to the source, or Hackage
        version string.
      '';
      default = { };
    };
    overrides = mkOption {
      type = haskellOverlayType;
      description = ''
        Cabal package overrides for this Haskell project
                
        For handy functions, see 
        <https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix>

        **WARNING**: When using `imports`, multiple overlays
        will be merged using `lib.composeManyExtensions`.
        However the order the overlays are applied can be
        arbitrary (albeit deterministic, based on module system
        implementation).  Thus, the use of `overrides` via
        `imports` is not officiallly supported. If you'd like
        to see proper support, add your thumbs up to
        <https://github.com/NixOS/nixpkgs/issues/215486>.
      '';
      default = self: super: { };
      defaultText = lib.literalExpression "self: super: { }";
    };

    outputs = mkOption {
      type = outputsSubmodule;
      description = ''
        The flake outputs generated for this project.

        This is an internal option, not meant to be set by the user.
      '';
    };
    autoWire =
      let
        outputTypes = [ "packages" "checks" "apps" "devShells" ];
      in
      mkOption {
        type = types.listOf (types.enum outputTypes);
        description = ''
          List of flake output types to autowire.

          Using an empty list will disable autowiring entirely,
          enabling you to manually wire them using
          `config.haskellProjects.<name>.outputs`.
        '';
        default = outputTypes;
      };
  };
  config =
    let
      inherit (config.outputs) finalPackages;

      # TODO: finish implementing this.
      tracePackageSettings = k:
        (x:
          let
            x' = lib.mapAttrs
              (_: y:
                {
                  inherit (y.settings) check;
                } # builtins.removeAttrs y.settings [ "custom" "impl" "removeReferencesTo" ]
                // {
                  inherit (y) root local cabal;
                })
              x;
          in
          config.log.traceDebug "${k}: ${builtins.toJSON x'}" x);

      # Subet of config.packages that are local to the project.
      localPackages =
        lib.pipe config.packages [
          (lib.filterAttrs (_: cfg: cfg.local))
          (tracePackageSettings "localPackages")
        ];

      # We create *two* overlays, so that the latter settings overlay can access
      # the passthru stored in the first overlay.
      packagesOverlays = {
        sources = self: super:
          let
            isPathUnderNixStore = path: builtins.hasContext (builtins.toString path);
            build-haskell-package = import ../build-haskell-package.nix {
              inherit pkgs lib self super;
              inherit (config) log;
            };
          in
          lib.mapAttrs
            (name: cfg:
              let
                pkg =
                  if cfg.root == null
                  then if lib.hasAttr name super
                  then config.log.traceDebug "overlay.super: ${name}" super."${name}"
                  else config.log.throwError "Unknown package: ${name} (does not exist in basePackages)"
                  else
                    if isPathUnderNixStore cfg.root
                    then
                      config.log.traceDebug "overlay.callCabal2nix(build-haskell-package): ${cfg.root}"
                        (build-haskell-package name cfg.root)
                    else
                      config.log.traceDebug "overlay.callHackage: ${cfg.root} / ${builtins.typeOf cfg.root}"
                        (self.callHackage name cfg.root { });
              in
              # Add haskell-flake's metadata to the package's passthru.
                # This is useful in 'settings' overrides.
                # Eg: super.${name}.passthru.haskell-flake.cabal.executables != [ ];
              pkg.overrideAttrs (oa: {
                passthru = (oa.passthru or { }) // {
                  haskell-flake = {
                    inherit (cfg) cabal;
                  };
                };
              })
            )
            config.packages;

        settings = self: super:
          lib.mapAttrs
            (name: cfg:
              cfg.applySettings self super super.${name}
            )
            config.packages;
      };

      finalOverlay = lib.composeManyExtensions [
        # The order here matters.
        #
        # User's overrides (cfg.overrides) is applied **last** so
        # as to give them maximum control over the final package
        # set used.
        packagesOverlays.sources
        packagesOverlays.settings
        (pkgs.haskell.lib.packageSourceOverrides config.source-overrides)
        config.overrides
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

