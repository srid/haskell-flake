# Definition of the `haskellProjects.${name}` submodule's `config`
{ name, self, config, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo
    raw;

  # Like pkgs.runCommand but runs inside nix-shell with a mutable project directory.
  #
  # It currenty respects only the nativeBuildInputs (and no shellHook for
  # instance), which seems sufficient for our purposes. We also set $HOME and
  # make the project root mutable, because those are expected when running
  # something in a project shell (it is indeed the case with HLS).
  runCommandInSimulatedShell = devShell: projectRoot: name: attrs: command:
    pkgs.runCommand name (attrs // { inherit (devShell) nativeBuildInputs; })
      ''
        # Set pipefail option for safer bash
        set -euo pipefail

        # Copy project root to a mutable area
        # We expect "command" to mutate it.
        export HOME=$TMP
        cp -R ${projectRoot} $HOME/project
        chmod -R a+w $HOME/project
        pushd $HOME/project

        ${command}
        touch $out
      '';
  # TODO: dry!
  haskell-parsers = pkgs.callPackage ../haskell-parsers { };
  appType = import ../types/app-type.nix { inherit pkgs lib; };
  haskellOverlayType = import ../types/haskell-overlay-type.nix { inherit lib; };

  hlsCheckSubmodule = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        description = ''
          Whether to enable a flake check to verify that HLS works.
                  
          This is equivalent to `nix develop -i -c haskell-language-server`.

          Note that, HLS will try to access the network through Cabal (see 
          <https://github.com/haskell/haskell-language-server/issues/3128>),
          therefore sandboxing must be disabled when evaluating this
          check.
        '';
        default = false;
      };
      drv = mkOption {
        type = types.package;
        readOnly = true;
        description = ''
          The `hlsCheck` derivation generated for this project.
        '';
      };
    };
  };
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
  devShellSubmodule = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        description = ''
          Whether to enable a development shell for the project.
        '';
        default = true;
      };
      tools = mkOption {
        type = functionTo (types.attrsOf (types.nullOr types.package));
        description = ''
          Build tools for developing the Haskell project.
        '';
        default = hp: { };
        defaultText = ''
          Build tools useful for Haskell development are included by default.
        '';
      };
      extraLibraries = mkOption {
        type = functionTo (types.attrsOf (types.nullOr types.package));
        description = ''
          Extra Haskell libraries available in the shell's environment.
          These can be used in the shell's `runghc` and `ghci` for instance.

          The argument is the Haskell package set.

          The return type is an attribute set for overridability and syntax, as only the values are used.
        '';
        default = hp: { };
        defaultText = lib.literalExpression "hp: { }";
        example = lib.literalExpression "hp: { inherit (hp) releaser; }";
      };
      hlsCheck = mkOption {
        default = { };
        type = hlsCheckSubmodule;
        description = ''
          A [check](flake-parts.html#opt-perSystem.checks) to make sure that your IDE will work.
        '';
      };
      mkShellArgs = mkOption {
        type = types.attrsOf types.raw;
        description = ''
          Extra arguments to pass to `pkgs.mkShell`.
        '';
        default = { };
        example = ''
          {
            shellHook = \'\'
              # Re-generate .cabal files so HLS will work (per hie.yaml)
              ''${pkgs.findutils}/bin/find -name package.yaml -exec hpack {} \;
            \'\';
          };
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
      devShell = mkOption {
        type = types.package;
        readOnly = true;
        description = ''
          The development shell derivation generated for this project.
        '';
      };
      checks = mkOption {
        type = types.lazyAttrsOf types.package;
        readOnly = true;
        description = ''
          The flake checks generated for this project.
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
    devShell = mkOption {
      type = devShellSubmodule;
      description = ''
        Development shell configuration
      '';
      default = { };
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
      inherit (config.outputs) finalPackages finalOverlay packages;

      projectKey = name;

      localPackagesOverlay = self: _:
        let
          build-haskell-package = import ../build-haskell-package.nix {
            inherit pkgs lib self;
            inherit (config) log;
          };
        in
        lib.mapAttrs build-haskell-package config.packages;

      defaultBuildTools = hp: with hp; {
        inherit
          cabal-install
          haskell-language-server
          ghcid
          hlint;
      };
      nativeBuildInputs = lib.attrValues (defaultBuildTools finalPackages // config.devShell.tools finalPackages);
      mkShellArgs = config.devShell.mkShellArgs // {
        nativeBuildInputs = (config.devShell.mkShellArgs.nativeBuildInputs or [ ]) ++ nativeBuildInputs;
      };
      devShell = finalPackages.shellFor (mkShellArgs // {
        packages = p:
          map
            (name: p."${name}")
            (lib.attrNames config.packages);
        withHoogle = true;
        extraDependencies = p:
          let o = mkShellArgs.extraDependencies or (_: { }) p;
          in o // {
            libraryHaskellDepends = o.libraryHaskellDepends or [ ]
              ++ builtins.attrValues (config.devShell.extraLibraries p);
          };
      });

      buildPackageInfo = name: value: {
        package = finalPackages.${name};
        exes =
          let
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

      hlsCheck =
        runCommandInSimulatedShell
          devShell
          self "${projectKey}-hls-check"
          { } "haskell-language-server";
    in
    {
      outputs = {
        inherit devShell;

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

        finalPackages = config.basePackages.extend finalOverlay;

        packages = lib.mapAttrs buildPackageInfo config.packages;

        apps =
          lib.mkMerge
            (lib.mapAttrsToList (_: packageInfo: packageInfo.exes) packages);

        checks = lib.filterAttrs (_: v: v != null) {
          "${name}-hls" = if (config.devShell.enable && config.devShell.hlsCheck.enable) then hlsCheck else null;
        };

      };

      devShell.hlsCheck.drv = hlsCheck;
    };
}
