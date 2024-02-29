{ name, pkgs, lib, config, log, ... }:
let
  inherit (lib) types;
  inherit (import ./lib.nix {
    inherit lib config;
  }) mkCabalSettingOptions;

  # Convenient way to create multiple settings using `mkCabalSettingOptions`
  cabalSettingsFrom =
    lib.mapAttrsToList (name: args: {
      options = mkCabalSettingOptions (args // {
        inherit name;
      });
    });
in
{
  # NOTE: These settings are based on the functions in:
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix
  #
  # Some functions (like checkUnusedPackages) are not included here, but we
  # probably should, especially if there is demand.
  imports = with pkgs.haskell.lib.compose; cabalSettingsFrom {
    check = {
      type = types.bool;
      description = ''
        Whether to run cabal tests as part of the nix build
      '';
      impl = enable:
        lib.flip lib.pipe [
          (if enable then doCheck else dontCheck)
          (x: log.traceDebug "${name}.check ${builtins.toString enable} ${x.outPath}" x)
        ];
    };
    jailbreak = {
      type = types.bool;
      description = ''
        Remove version bounds from this package's cabal file.
      '';
      impl = enable:
        if enable then doJailbreak else dontJailbreak;
    };
    broken = {
      type = types.bool;
      description = ''
        Whether to mark the package as broken
      '';
      impl = enable:
        if enable then markBroken else unmarkBroken;
    };
    brokenVersions = {
      type = types.attrsOf types.str;
      description = ''
        List of versions that are known to be broken.
      '';
      impl = versions:
        let
          markBrokenVersions = vs: drv:
            builtins.foldl' markBrokenVersion drv vs;
        in
        markBrokenVersions versions;
    };
    haddock = {
      type = types.bool;
      description = ''
        Whether to build the haddock documentation.
      '';
      impl = enable:
        if enable then doHaddock else dontHaddock;
    };
    coverage = {
      type = types.bool;
      description = ''
             Modifies thae haskell package to disable the generation
        and installation of a coverage report.
      '';
      impl = enable:
        if enable then doCoverage else dontCoverage;
    };
    benchmark = {
      type = types.bool;
      description = ''
        Enables dependency checking and compilation
        for benchmarks listed in the package description file.
        Benchmarks are, however, not executed at the moment.
      '';
      impl = enable:
        if enable then doBenchmark else dontBenchmark;
    };
    libraryProfiling = {
      type = types.bool;
      description = ''
        Build the library for profiling by default.
      '';
      impl = enable:
        if enable then enableLibraryProfiling else disableLibraryProfiling;
    };
    executableProfiling = {
      type = types.bool;
      description = ''
        Build the executable with profiling enabled.
      '';
      impl = enable:
        if enable then enableExecutableProfiling else disableExecutableProfiling;
    };
    sharedExecutables = {
      type = types.bool;
      description = ''
        Build the executables as shared libraries.
      '';
      impl = enable:
        if enable then enableSharedExecutables else disableSharedExecutables;
    };
    sharedLibraries = {
      type = types.bool;
      description = ''
        Build the libraries as shared libraries.
      '';
      impl = enable:
        if enable then enableSharedLibraries else disableSharedLibraries;
    };
    deadCodeElimination = {
      type = types.bool;
      description = ''
        Enable dead code elimination.
      '';
      impl = enable:
        if enable then enableDeadCodeElimination else disableDeadCodeElimination;
    };
    staticLibraries = {
      type = types.bool;
      description = ''
        Build the libraries as static libraries.
      '';
      impl = enable:
        if enable then enableStaticLibraries else disableStaticLibraries;
    };
    extraBuildDepends = {
      type = types.listOf types.package;
      description = ''
        Extra build dependencies for the package.
      '';
      impl = addBuildDepends;
    };
    extraBuildTools = {
      type = types.listOf types.package;
      description = ''
        Extra build tools for the package.
      '';
      impl = addBuildTools;
    };
    extraLibraries = {
      type = types.listOf types.package;
      description = ''
        Extra library dependencies for the package.
      '';
      impl = addExtraLibraries;
    };
    extraTestToolDepends = {
      type = types.listOf types.package;
      description = ''
        Extra test tool dependencies for the package.
      '';
      impl = addTestToolDepends;
    };
    extraPkgconfigDepends = {
      type = types.listOf types.package;
      description = ''
        Extra pkgconfig dependencies for the package.
      '';
      impl = addPkgconfigDepends;
    };
    extraSetupDepends = {
      type = types.listOf types.package;
      description = ''
        Extra setup dependencies for the package.
      '';
      impl = addSetupDepends;
    };
    extraConfigureFlags = {
      type = types.listOf types.str;
      description = ''
        Extra flags to pass to 'cabal configure'
      '';
      impl = appendConfigureFlags;
    };
    extraBuildFlags = {
      type = types.listOf types.str;
      description = ''
        Extra flags to pass to 'cabal build'
      '';
      impl = appendBuildFlags;
    };
    removeConfigureFlags = {
      type = types.listOf types.str;
      description = ''
        Flags to remove from the default flags passed to 'cabal configure'
      '';
      impl =
        let
          removeConfigureFlags = flags: drv:
            builtins.foldl' removeConfigureFlag drv flags;
        in
        removeConfigureFlags;
    };
    cabalFlags = {
      type = types.attrsOf types.bool;
      description = ''
        Cabal flags to enable or disable explicitly.
      '';
      impl = flags: drv:
        let
          fns = lib.flip lib.mapAttrsToList flags (flag: enabled:
            (if enabled then enableCabalFlag else disableCabalFlag) flag
          );
        in
        lib.pipe drv fns;
    };
    patches = {
      type = types.listOf types.path;
      description = ''
        A list of patches to apply to the package.
      '';
      impl = appendPatches;
    };
    justStaticExecutables = {
      type = types.bool;
      description = ''
        Link executables statically against haskell libs to reduce closure size
      '';
      impl = enable:
        if enable then justStaticExecutables else x: x;
    };
    separateBinOutput = {
      type = types.bool;
      description = ''
        Create two outputs for this Haskell package -- 'out' and 'bin'. This is
        useful to separate out the binary with a reduced closure size.

        WARNING: This can lead to cyclic references; see
        https://github.com/srid/haskell-flake/issues/167
      '';
      impl = enable:
        let
          disableSeparateBinOutput =
            overrideCabal (drv: { enableSeparateBinOutput = false; });
        in
        if enable then enableSeparateBinOutput else disableSeparateBinOutput;
    };
    buildTargets = {
      type = types.listOf types.str;
      description = ''
        A list of targets to build.

        By default all cabal executable targets are built.
      '';
      impl = setBuildTargets;
    };
    hyperlinkSource = {
      type = types.bool;
      description = ''
        Whether to hyperlink the source code in the generated documentation.
      '';
      impl = enable:
        if enable then doHyperlinkSource else dontHyperlinkSource;
    };
    disableHardening = {
      type = types.bool;
      description = ''
        Disable hardening flags for the package.
      '';
      impl = enable:
        if enable then disableHardening else x: x;
    };
    strip = {
      type = types.bool;
      description = ''
        Let Nix strip the binary files.
        
        This removes debugging symbols.
      '';
      impl = enable:
        if enable then doStrip else dontStrip;
    };
    enableDWARFDebugging = {
      type = types.bool;
      description = ''
        Enable DWARF debugging.
      '';
      impl = enable:
        if enable then enableDWARFDebugging else x: x;
    };
    disableOptimization = {
      type = types.bool;
      description = ''
        Disable core optimizations, significantly speeds up build time
      '';
      impl = enable:
        if enable then disableOptimization else x: x;
    };
    failOnAllWarnings = {
      type = types.bool;
      description = ''
        Turn on most of the compiler warnings and fail the build if any of them occur
      '';
      impl = enable:
        if enable then failOnAllWarnings else x: x;
    };
    triggerRebuild = {
      type = types.raw;
      description = ''
        Add a dummy command to trigger a build despite an equivalent earlier
        build that is present in the store or cache.  
      '';
      impl = triggerRebuild;
    };

    buildFromSdist = {
      type = types.bool;
      description = ''
        Whether to use `buildFromSdist` to build the package.

        Make sure all files we use are included in the sdist, as a check
        for release-worthiness.
      '';
      impl = enable:
        if enable then
          (pkg: lib.pipe pkg [
            buildFromSdist
            (x: log.traceDebug "${name}.buildFromSdist ${x.outPath}" x)
          ]) else x: x;
    };

    removeReferencesTo = {
      type = types.listOf types.package;
      description = ''
        Packages to remove references to.

        This is useful to ditch unnecessary data dependencies from your Haskell
        executable so as to reduce its closure size.

        cf.
        - https://github.com/NixOS/nixpkgs/pull/204675
        - https://srid.ca/remove-references-to
      '';
      impl = disallowedReferences: drv:
        drv.overrideAttrs (old: rec {
          inherit disallowedReferences;
          postInstall = (old.postInstall or "") + ''
            ${lib.concatStrings (map (e: "echo Removing reference to: ${e}\n") disallowedReferences)}
            ${lib.concatStrings (map (e: "remove-references-to -t ${e} $out/bin/*\n") disallowedReferences)}
          '';
        });
    };

    # When none of the above settings is suitable:
    custom = {
      type = types.functionTo types.package;
      description = ''
        A custom funtion to apply on the Haskell package.

        Use this only if none of the existing settings are suitable.

        The function must take three arguments: self, super and the package being
        applied to.

        Example:

            custom = pkg: builtins.trace pkg.version pkg;
      '';
      impl = f: f;
    };
  };
}
