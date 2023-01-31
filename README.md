# haskell-flake

A [`flake-parts`](https://flake.parts/) Nix module for Haskell development.

## Why?

To keep `flake.nix` smaller (see examples below) and declarative ([what](https://github.com/srid/emanote-template/blob/c955a08fa685adb2fb81c4d8cefac6e20f417fee/flake.nix#L19-L26) vs [how](https://github.com/srid/emanote-template/blob/78d64b6e1e3497e3bd97012d8bf6f8bd6ec9cdd3/flake.nix#L19-L57)) by bringing a NixOS-like [module system](https://nixos.org/manual/nixos/stable/index.html#sec-writing-modules) to flakes (through `flake-parts`).

## Usage

To use `haskell-flake` in your Haskell projects, run:

``` nix
nix flake init -t github:srid/haskell-flake
```

This will generate a template Haskell project with a `flake.nix`. If you already have a Haskell project, copy over this `flake.nix` and adjust accordingly.

### Template

If you are bootstrapping a *new* Haskell project, you may use https://github.com/srid/haskell-template which already uses `haskell-flake` along with other opinionated defaults.

## Documentation

Check out the [list of options](https://flake.parts/options/haskell-flake.html). `haskell-flake` uses [`callCabal2nix` and `shellFor`](https://github.com/srid/haskell-multi-nix/blob/nixpkgs/flake.nix) under the hood.

## Examples

- Simple
  - https://github.com/srid/haskell-template/blob/master/flake.nix
  - https://github.com/fpindia/fpindia-site/blob/master/flake.nix
  - https://github.com/srid/haskell-multi-nix/blob/master/flake.nix (Demonstrates multiple local packages)
- Complex: 
  - https://github.com/srid/emanote/blob/master/flake.nix
  - https://github.com/srid/ema/blob/master/flake.nix
