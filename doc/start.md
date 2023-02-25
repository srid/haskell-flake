---
order: -10
---

# Getting Started

Before using `haskell-flake` you must first [install Nix](https://nixos.org/download.html) and [enable flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes).

## Existing projects

To use `haskell-flake` in an *existing* Haskell project, run:

``` nix
nix flake init -t github:srid/haskell-flake
```

Open the generated `flake.nix` and change `self'.packages.example` to use your package name. For example, if your package is named `my-package` (with a `my-package.cabal` file), change `example` to `my-package`.

## New projects

To create a *new* Haskell project, instead, run:

``` nix
nix flake init -t github:srid/haskell-flake#example
```

### Template

You may also use https://github.com/srid/haskell-template which already uses `haskell-flake` along with other opinionated defaults.

## Next steps

Visit [[guide]] for more details, and [[ref]] for module options.