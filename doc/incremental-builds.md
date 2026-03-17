# Incremental builds

By default, Nix builds Haskell packages from scratch every time a source file changes. For large projects this can be slow, as the entire package is recompiled even if only a single module was modified. Incremental builds address this by caching and reusing intermediate build artifacts across builds.

## Getting started

The [haskell-incremental-build-template](https://github.com/juspay/haskell-incremental-build-template) provides a template for setting up incremental builds with haskell-flake. Refer to its README for setup instructions and usage details.

## Future

[Sandstone](https://github.com/obsidiansystems/sandstone) - when ready - is a better fit for doing incremental builds. It uses Nix's dynamic derivations to generate a derivation per module.
