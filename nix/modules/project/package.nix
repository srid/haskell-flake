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
  mkSelfSuperOption = attrs:
    let
      withSelfSuper = t:
        types.either t (types.functionTo (types.functionTo t));
      selfSuperDescription = ''

    Optionally accepts arguments 'self' and 'super' reflecting the Haskell
    overlay arguments.
  '';
    in
    mkOption (attrs // {
      type = types.nullOr (withSelfSuper attrs.type);
      description = attrs.description + selfSuperDescription;
      default = null;
    });
  applySelfSuper = self: super: f:
    if builtins.isFunction f then f self super else f;

in
{ config, ... }: {
  options = {
    # TODO: Rename this to 'source'?
    root = mkOption {
      type = types.nullOr (types.either types.path types.string);
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
    settings = mkOption {
      default = { };
      type = types.submoduleWith {
        specialArgs = { inherit pkgs lib; };
        modules = [
          {
            imports = [
              ./settings
            ];
            options = {

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

              # Additional functionality not in nixpkgs
              # TODO: Instead of baking this in haskell-flake, can we instead allow the
              # user to define these 'custom' options? Are NixOS modules flexible enough
              # for that?
              removeReferencesTo = mkSelfSuperOption {
                type = types.listOf types.package;
                description = ''
                  Packages to remove references to.

                  This is useful to ditch data dependencies, from your Haskell executable,
                  that are not needed at runtime.

                  cf. 
                  - https://github.com/NixOS/nixpkgs/pull/204675
                  - https://srid.ca/remove-references-to
                '';
              };
            };
          }
        ];
      };
    };

    applySettings = mkOption {
      type = types.functionTo (types.functionTo (types.functionTo types.package));
      internal = true;
      # FIXME: why can't we set this when using project-modules.nix?
      # readOnly = true;
      description = ''
        A function that applies all the 'settings' in this module.
        
        `pkgs.haskell.lib.compose` is used to apply the overrides.
      '';
      default = self: super: with pkgs.haskell.lib.compose;
        let
          selfSupered = applySelfSuper self super;
          settings = config.settings;
        in
        lib.flip lib.pipe (
          (settings.impl.check self super)
          ++
          (settings.impl.extraBuildDepends self super)
          ++
          lib.optional (settings.haddock != null)
            (if settings.haddock then doHaddock else dontHaddock)
          ++
          lib.optional settings.justStaticExecutables
            justStaticExecutables
          ++
          lib.optional (settings.libraryProfiling != null)
            (if settings.libraryProfiling then enableLibraryProfiling else disableLibraryProfiling)
          ++
          lib.optional (settings.executableProfiling != null)
            (if settings.executableProfiling then enableExecutableProfiling else disableExecutableProfiling)
          ++
          lib.optional (settings.removeReferencesTo != null)
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
              removeReferencesTo (selfSupered settings.removeReferencesTo)
            )
        );
    };
  };
}
