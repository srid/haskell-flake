# Revision history for haskell-flake

## `master` branch

- New features
  - #63: Add `config.haskellProjects.${name}.outputs` containing all flake outputs for that project.
  - #49 & #91: The `packages` option now autodiscovers the top-level `.cabal` file (in addition to looking inside sub-directories) as its default value.
  - #69: The default flake template creates `flake.nix` only, while the `#example` one creates the full Haskell project template.
  - #92: Add `devShell.mkShellArgs` to pass custom arguments to `mkShell`
  - #100: `source-overrides` option now supports specifying Hackage versions.
- API changes
    - #37: Group `buildTools` (renamed to `tools`), `hlsCheck` and `hlintCheck` under the `devShell` submodule option; and allow disabling them all using `devShell.enable = false;` (useful if you want haskell-flake to produce just the package outputs).
    - #64: Remove hlintCheck (use [treefmt-nix](https://github.com/numtide/treefmt-nix#flake-parts) instead)
    - #52: Expose the final package set as `finalPackages`. Rename `haskellPackages`, accordingly, to `basePackages`. Overlays are applied on top of `basePackage` -- using `source-overrides`, `overrides`, `packages` in that order -- to produce `finalPackages`.
    - #68: You can now use `imports` inside of `haskellProjects.<name>` to modularize your Haskell project configuration.
      - #79: `flake.haskellFlakeProjectModules.<name>` option can be used to set and expose your Haskell project modules to other flakes.
      - #67: `overrides` will be combined using `composeManyExtensions`, however their order is arbitrary. This is an experimental feature, and a warning will be logged.

## 0.1.0

- Initial release
