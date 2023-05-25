{ pkgs, lib, config, ... }:
let
  inherit (lib) types;
  inherit (import ./lib.nix {
    inherit lib config;
  }) mkCabalSettingOptions;
in
{
  # TODO: This list contains the most often used functions. We should complete
  # it with what's left in 
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix
  imports = with pkgs.haskell.lib.compose; [
    {
      options = mkCabalSettingOptions {
        name = "check";
        type = types.bool;
        description = ''
          Whether to run cabal tests as part of the nix build
        '';
        impl = enable:
          if enable then doCheck else dontCheck;
      };
    }

    {
      options = mkCabalSettingOptions {
        name = "jailbreak";
        type = types.bool;
        description = ''
          Remove version bounds from this package's cabal file.
        '';
        impl = enable:
          if enable then doJailbreak else dontJailbreak;
      };
    }

    {
      options = mkCabalSettingOptions {
        name = "broken";
        type = types.bool;
        description = ''
          Whether to mark the package as broken
        '';
        impl = enable:
          if enable then markBroken else unmarkBroken;
      };
    }

    {
      options = mkCabalSettingOptions {
        name = "haddock";
        type = types.bool;
        description = ''
          Whether to build the haddock documentation.
        '';
        impl = enable:
          if enable then doHaddock else dontHaddock;
      };
    }

    {
      options = mkCabalSettingOptions {
        name = "coverage";
        type = types.bool;
        description = ''
               Modifies thae haskell package to disable the generation
          and installation of a coverage report.
        '';
        impl = enable:
          if enable then doCoverage else dontCoverage;
      };
    }

    {
      options = mkCabalSettingOptions {
        name = "benchmark";
        type = types.bool;
        description = ''
          Enables dependency checking and compilation
          for benchmarks listed in the package description file.
          Benchmarks are, however, not executed at the moment.
        '';
        impl = enable:
          if enable then doBenchmark else dontBenchmark;
      };
    }

    {
      options = mkCabalSettingOptions {
        name = "libraryProfiling";
        type = types.bool;
        description = ''
          Build the library for profiling by default.
        '';
        impl = enable:
          if enable then enableLibraryProfiling else disableLibraryProfiling;
      };
    }

    {
      options = mkCabalSettingOptions {
        name = "executableProfiling";
        type = types.bool;
        description = ''
          Build the executable with profiling enabled.
        '';
        impl = enable:
          if enable then enableExecutableProfiling else disableExecutableProfiling;
      };
    }

    {
      options = mkCabalSettingOptions {
        name = "extraBuildDepends";
        type = types.listOf types.package;
        description = ''
          Extra build dependencies for the package.
        '';
        impl = addBuildDepends;
      };
    }

    {
      options = mkCabalSettingOptions {
        name = "extraConfigureFlags";
        type = types.listOf types.string;
        description = ''
          Extra flags to pass to 'cabal configure'
        '';
        impl = appendConfigureFlags;
      };
    }

    {
      options = mkCabalSettingOptions {
        name = "patches";
        type = types.listOf types.path;
        description = ''
          A list of patches to apply to the package.
        '';
        impl = appendPatches;
      };
    }

    {
      options = mkCabalSettingOptions {
        name = "justStaticExecutables";
        type = types.bool;
        description = ''
          Link executables statically against haskell libs to reduce closure size
        '';
        impl = enable:
          if enable then justStaticExecutables else x: x;
      };
    }

    {
      options = mkCabalSettingOptions {
        name = "separateBinOutput";
        type = types.bool;
        description = ''
          Create two outputs for this Haskell package -- 'out' and 'bin'. This is
          useful to separate out the binary with a reduced closure size.
        '';
        impl = enable:
          let
            disableSeparateBinOutput =
              overrideCabal (drv: { enableSeparateBinOutput = false; });
          in
          if enable then enableSeparateBinOutput else disableSeparateBinOutput;
      };
    }

    {
      options = mkCabalSettingOptions {
        name = "custom";
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
    }
  ];
}
