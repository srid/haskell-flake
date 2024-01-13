# Getting Started

Before using `haskell-flake` you must first [install Nix](https://flakular.in/install).

## Existing projects

To use `haskell-flake` in an *existing* Haskell project, run:

```bash
nix flake init -t github:srid/haskell-flake
```

Open the generated `flake.nix` and change `self'.packages.example` to use your package name. For example, if your package is named `my-package` (with a `my-package.cabal` file), change `example` to `my-package`. Follow the comments along the `flake.nix` to make any necessary changes to the project configuration.

## New projects

To create a *new* Haskell project, instead, run:

```bash
mkdir example && cd ./example
nix flake init -t github:srid/haskell-flake#example
```

### Template

You may also use https://github.com/srid/haskell-template which already uses `haskell-flake` along with other opinionated defaults.

## Under the hood

:::tip Under the hood
See [this tutorial](https://nixos.asia/en/nixify-haskell-nixpkgs) to understand what it takes to package a Haskell application without haskell-flake.
:::

When nixifying a Haskell project without flake-parts (thus without haskell-flake) you would generally use the [raw Haskell infrastructure from nixpkgs](https://nixos.asia/en/nixify-haskell-nixpkgs). haskell-flake uses these functions, while exposing a simpler [modular](https://flake.parts) API on top: your `flake.nix` becomes more [declarative](https://github.com/srid/haskell-template/blob/304fb5a1adfb25c7691febc15911b588a364a5f7/flake.nix#L27-L39) and less [imperative](https://github.com/srid/haskell-template/blob/3fc6858830ecee3d2fe1dfe9a8bfa2047cf561ac/flake.nix#L20-L79).

In addition, compared to using plain nixpkgs, haskell-flake supports:

- Auto-detection of local packages based on `cabal.project` file (via [haskell-parsers](https://github.com/srid/haskell-flake/tree/master/nix/haskell-parsers))
- Parse executables from `.cabal` file
- Modular interface to `pkgs.haskell.lib.compose.*` (via `packages` and `settings` submodules)
- Composition of dependency overrides, and other project settings, via [[modules]]

## Next steps

Visit [[guide]] for more details, and [[ref]] for module options.
