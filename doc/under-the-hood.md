
# Under the hood

>[!tip] Under the hood
> See [this tutorial](https://nixos.asia/en/nixify-haskell-nixpkgs) to understand what it takes to package a Haskell application without haskell-flake.

When nixifying a Haskell project without flake-parts (thus without haskell-flake) you would generally use the [raw Haskell infrastructure from nixpkgs](https://nixos.asia/en/nixify-haskell-nixpkgs). haskell-flake uses these functions, while exposing a simpler [modular](https://flake.parts) API on top: your `flake.nix` becomes more [declarative] and less [imperative].

[declarative]: https://github.com/srid/haskell-template/blob/033913a6fe418ea0c25ec2c2604ab4030563ba2e/flake.nix#L22-L59
[imperative]: https://github.com/srid/haskell-template/blob/3fc6858830ecee3d2fe1dfe9a8bfa2047cf561ac/flake.nix#L20-L79

In addition, compared to using plain nixpkgs, haskell-flake supports:

- Auto-detection of [[local|local packages]] based on `cabal.project` file (via [haskell-parsers](https://github.com/srid/haskell-flake/tree/master/nix/haskell-parsers))
- Parse executables from `.cabal` file, to create Flake apps.
- Modular interface to `pkgs.haskell.lib.compose.*` (via `packages` and `settings` submodules)
- Composition of dependency overrides, and other project settings, via [[modules]]

See #[[start]] for getting started with haskell-flake.
