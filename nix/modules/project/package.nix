# TODO: Can we refactor this module by decomposing the individual options?
#
# Esp. to decouple removeReferencesTo, either in this repo or in user repo.
{ project, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;

  # Wrap a type such that we can pass *optional* 'self' and 'super' arguments.
  # This is poor man's module system, which we cannot use for whatever reason.
  withSelfSuper = t:
    types.either t (types.functionTo (types.functionTo t));
  applySelfSuper = self: super: f:
    if builtins.isFunction f then f self super else f;
  selfSuperDescription = ''

    Optionally accepts arguments 'self' and 'super' reflecting the Haskell
    overlay arguments.
  '';
in
{ config, ... }: {
  options = {
    root = mkOption {
      type = types.nullOr (types.either types.string types.path);
      description = ''
        Path containing the Haskell package's `.cabal` file.

        Or version string for a version in Hackage.
      '';
      default = null;
    };

    local = mkOption {
      type = types.bool;
      description = ''
        Whether this package is local to the flake.
      '';
      internal = true;
      # FIXME: why can't we set this when using project-modules.nix?
      # readOnly = true;
      default =
        let
          t = x: builtins.trace x x;
        in
        config.root != null &&
        lib.strings.hasPrefix (t "${project.config.projectRoot}") "${config.root}";
      defaultText = ''
        Computed automatically if package 'root' is under 'projectRoot'.
      '';
    };

    # cabal2nix stuff goes here.

    check = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Whether to run cabal tests as part of the nix build
      '';
      default = null;
    };

    haddock = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Whether to generate haddock documentation as part of the nix build
      '';
      default = null;
    };

    justStaticExecutables = mkOption {
      type = types.bool;
      description = ''
        Link executables statically against haskell libs to reduce closure size
      '';
      default = false;
    };

    libraryProfiling = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Whether to build the library with profiling enabled
      '';
      default = null;
    };

    executableProfiling = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Whether to build executables with profiling enabled
      '';
      default = null;
    };

    extraBuildDepends = mkOption {
      type = types.nullOr (withSelfSuper (types.listOf types.package));
      description = ''
        Extra build dependencies for the package.
      '' + selfSuperDescription;
      default = null;
    };

    # Additional functionality not in nixpkgs
    # TODO: Instead of baking this in haskell-flake, can we instead allow the
    # user to define these 'custom' options? Are NixOS modules flexible enough
    # for that?
    removeReferencesTo = mkOption {
      type = withSelfSuper (types.listOf types.package);
      description = ''
        Packages to remove references to.

        This is useful to ditch data dependencies, from your Haskell executable,
        that are not needed at runtime.

        cf. 
        - https://github.com/NixOS/nixpkgs/pull/204675
        - https://srid.ca/remove-references-to
      '' + selfSuperDescription;
      default = [ ];
    };

    apply = mkOption {
      type = types.functionTo (types.functionTo (types.functionTo types.package));
      internal = true;
      # FIXME: why can't we set this when using project-modules.nix?
      # readOnly = true;
      description = ''
        A function that applies all the overrides in this module.
        
        `pkgs.haskell.lib.compose` is used to apply the override.
      '';
      default = self: super: with pkgs.haskell.lib.compose;
        let
          selfSupered = applySelfSuper self super;
        in
        lib.flip lib.pipe (
          lib.optional (config.check != null)
            (if config.check then doCheck else dontCheck)
          ++
          lib.optional (config.haddock != null)
            (if config.haddock then doHaddock else dontHaddock)
          ++
          lib.optional config.justStaticExecutables
            justStaticExecutables
          ++
          lib.optional (config.libraryProfiling != null)
            (if config.libraryProfiling then enableLibraryProfiling else disableLibraryProfiling)
          ++
          lib.optional (config.executableProfiling != null)
            (if config.executableProfiling then enableExecutableProfiling else disableExecutableProfiling)
          ++
          lib.optional (config.extraBuildDepends != null && config.extraBuildDepends != [ ])
            (addBuildDepends (selfSupered config.extraBuildDepends))
          ++
          lib.optional (config.removeReferencesTo != [ ])
            (
              let
                # Remove the given references from drv's executables.
                # We shouldn't need this after https://github.com/haskell/cabal/pull/8534
                removeReferencesTo = disallowedReferences: drv:
                  drv.overrideAttrs (old: rec {
                    inherit disallowedReferences;
                    # Ditch data dependencies that are not needed at runtime.
                    # cf. https://github.com/NixOS/nixpkgs/pull/204675
                    # cf. https://srid.ca/remove-references-to
                    postInstall = (old.postInstall or "") + ''
                      ${lib.concatStrings (map (e: "echo Removing reference to: ${e}\n") disallowedReferences)}
                      ${lib.concatStrings (map (e: "remove-references-to -t ${e} $out/bin/*\n") disallowedReferences)}
                    '';
                  });
              in
              removeReferencesTo (selfSupered config.removeReferencesTo)
            )
        );
    };
  };
}
