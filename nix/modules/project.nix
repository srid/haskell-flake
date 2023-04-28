# Definition of the `haskellProjects.${name}` submodule's `config`
{ name, self, config, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    raw;

  appType = import ../types/app-type.nix { inherit pkgs lib; };
  haskellOverlayType = import ../types/haskell-overlay-type.nix { inherit lib; };

  packageSubmodule = with types; submodule {
    options = {
      root = mkOption {
        type = path;
        description = ''
          The directory path under which the Haskell package's `.cabal`
          file or `package.yaml` resides.
        '';
      };
    };
  };

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
    ./project/devshell.nix
    ./project/defaults.nix
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
    packages = mkOption {
      type = types.lazyAttrsOf packageSubmodule;
      description = ''
        Set of local packages in the project repository.

        If you have a `cabal.project` file (under `projectRoot`),
        those packages are automatically discovered. Otherwise, a
        top-level .cabal or package.yaml file is used to discover
        the single local project.

        haskell-flake currently supports a limited range of syntax
        for `cabal.project`. Specifically it requires an explicit
        list of package directories under the "packages" option.
      '';
      default =
        let
          haskell-parsers = import ../haskell-parsers {
            inherit pkgs lib;
            throwError = msg: config.log.throwError ''
              A default value for `packages` cannot be auto-determined:

                ${msg}

              Please specify the `packages` option manually or change your project configuration (cabal.project).
            '';
          };
        in
        lib.pipe config.projectRoot [
          haskell-parsers.findPackagesInCabalProject
          (x: config.log.traceDebug "config.haskellProjects.${name}.packages = ${builtins.toJSON x}" x)

          (lib.mapAttrs (_: path: { root = path; }))
        ];
      defaultText = lib.literalMD "autodiscovered by reading `self` files.";
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
      inherit (config.outputs) finalPackages packages;

      localPackagesOverlay = self: _:
        let
          build-haskell-package = import ../build-haskell-package.nix {
            inherit pkgs lib self;
            inherit (config) log;
          };
        in
        lib.mapAttrs build-haskell-package config.packages;

      finalOverlay = lib.composeManyExtensions [
        # The order here matters.
        #
        # User's overrides (cfg.overrides) is applied **last** so
        # as to give them maximum control over the final package
        # set used.
        localPackagesOverlay
        (pkgs.haskell.lib.packageSourceOverrides config.source-overrides)
        config.overrides
      ];

      buildPackageInfo = name: value: {
        package = finalPackages.${name};
        exes =
          let
            haskell-parsers = import ../haskell-parsers {
              inherit pkgs lib;
              throwError = msg: config.log.throwError ''
                Unable to determine executable names for package ${name}:

                  ${msg}
              '';
            };
            exeNames = haskell-parsers.getCabalExecutables value.root;
          in
          lib.listToAttrs
            (map
              (exe:
                lib.nameValuePair exe {
                  program = "${lib.getBin finalPackages.${name}}/bin/${exe}";
                }
              )
              exeNames
            );
      };

    in
    {
      outputs = {
        inherit finalOverlay;

        finalPackages = config.basePackages.extend finalOverlay;

        packages = lib.mapAttrs buildPackageInfo config.packages;

        apps =
          lib.mkMerge
            (lib.mapAttrsToList (_: packageInfo: packageInfo.exes) packages);
      };
    };
}
