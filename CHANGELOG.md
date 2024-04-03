# Revision history for haskell-flake

## Unreleased (0.5.0)

- Breaking changes
  - #221: Switch from `buildFromCabalSdist` to `buildFromSdist`, to allow using non-standard package sets (wherein `cabal-install` is otherwise built without using user's overrides)
    - #253: Enable controlling `buildFromSdist` through `settings.<name>.buildFromSdist`. (This was turned off by default originally, but was turned on by default in #286, limited to local packages in #298)
- Enhancements
  - `settings` module:
    - #210: Add `extraLibraries` to `settings` module.
    - #225: Add `removeReferencesTo` to `settings` module.
  - #277: Add `otherOverlays` option to add custom Haskell package overlays.
  - #215: Improved debug logging.
    - #216: Remove `debug` option (pass `--trace-verbose` to nix instead)
- Fixes
  - #222: Improve `cabal.project` parser by handling files not ending with newline
  - #271, #223: Change all `types.attrsOf` to `types.lazyAttrsOf`. If you use `lib.mkIf` for `attrsOf` values (not `submodule` options), use `lib.optionalAttrs` instead. This fixes #270 (`basePackages`) and improves performance.
  - #296: Fix `removeConfigureFlags` to actually work.
  - #297: Fix `brokenVersions` to actually work.

## 0.4.0 (Aug 22, 2023)

- #162: **Completely new way to override Haskell packages**: removed `overrides` and `source-overrides`. Use `packages` to specify your source overrides; use `settings` to override individual packages in modular fashion (like NixOS modules). Additional changes include:
  - Add `package.<name>.cabal.executables` referring to the executables in a package. This is auto-detected by parsing the Cabal file.
  - Add `packages.<name>.local.*` to determine of a package is a local package or not.
  - Add `projectFlakeName` option (useful in debug logging prefix)
  - `flake.haskellFlakeProjectModules`: Dropped all defaults, except the `output` module, which now exports `packages` and `settings`. Added a `defaults.projectModules.output` option that allows the user to override this module, or directly access the generated module.
  - Add `project.config.defaults.settings.default` defining sensible defaults for local packages.
  - Add `project.config.defaults.enable` to turn off all default settings en masse.
  - Regressions in this PR: #169, #178
- #175: `devShell`: Add options `benchmark` (to enable benchmark dependencies) and `hoogle` (whether to include Hoogle in development shell)
- #189: Use `types.str` instead of `types.string` in option types

## 0.3.0 (May 22, 2023)

- #134: Add `autoWire` option to control generation of flake outputs
  - #138: Add `checks` to `outputs` submodule
  - #143: Changed `autoWire` to be an enum type, for granular controlling of which outputs to autowire.
- #137: Expose cabal executables as flake apps. Add a corresponding `outputs.apps` option, while the `outputs.localPackages` option is renamed to `outputs.packages` (it now contains package metadata, including packages and its executables).
  - #151: Use `lib.getBin` to get the bin output
- #148: Remove automatic hpack->cabal generation. Use `pre-commit-hooks.nix` instead.
- #149: Fix unnecessary re-runs of cabal2nix evaluation. Add a `debug` option to have haskell-flake produce diagnostic messages.
- #153: Add `config.defaults` submodule to allow overriding the default devShell tools added by haskell-flake

## 0.2.0 (Mar 13, 2023)

- New features
  - #68, #79, #106: Add support for project modules that can be imported in `imports`. Export them in `flake.haskellFlakeProjectModules`. Default modules are exported by default, to reuse overrides and local packages from external flakes. For details, see https://haskell.flake.page/modules
    - #67: `overrides` will be combined using `composeManyExtensions`, however their order is arbitrary. This is an experimental feature, and a warning will be logged.
  - Dev shell
    - #37: Devshell can now be disabled using `devShell.enable = false;` (useful if you want haskell-flake to produce just the package outputs)
    - #92: Add `devShell.mkShellArgs` to pass custom arguments to `mkShell`
    - #111: Add `devShell.extraLibraries` to add custom Haskell libraries to the devshell.
  - #63, #52: Add `config.haskellProjects.${name}.outputs` containing all flake outputs for that project; as well as (#102) `finalPackages` and `localPackages`.
  - #49 & #91 & #110: The default value for the `packages` option is now determined from the `cabal.project` file. If it doesn't exist, it looks for top-level `.cabal` file or `package.yaml`. Better hpack support throughout.
  - #100: `source-overrides` option now supports specifying Hackage versions as string.
  - #114: Prevent unnecessary Nix rebuilds of packages in sub-directories when parent contents change.
- API changes
  - #37: Group `buildTools` (renamed to `tools`), `hlsCheck` and `hlintCheck` under the new `devShell` submodule option
  - #64: Remove hlintCheck (use [treefmt-nix](https://github.com/numtide/treefmt-nix#flake-parts) instead)
  - #52: Rename `haskellPackages` to `basePackages`. Overlays are applied on top of `basePackage` -- using `source-overrides`, `overrides`, `packages` in that order -- to produce `finalPackages`.
  - #69: The default flake template creates `flake.nix` only, while the `#example` one creates the full Haskell project template.

## 0.1.0 (Feb 1, 2023)

- Initial release
