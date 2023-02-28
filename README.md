# haskell-flake

A [`flake-parts`](https://flake.parts/) module to make Haskell development easier with Nix.

## Why?

To keep `flake.nix` smaller (see examples below) and declarative ([what](https://github.com/srid/emanote-template/blob/c955a08fa685adb2fb81c4d8cefac6e20f417fee/flake.nix#L19-L26) vs [how](https://github.com/srid/emanote-template/blob/78d64b6e1e3497e3bd97012d8bf6f8bd6ec9cdd3/flake.nix#L19-L57)) by bringing a NixOS-like [module system](https://nixos.org/manual/nixos/stable/index.html#sec-writing-modules) to flakes. 
 `haskell-flake` simply uses [`callCabal2nix` and `shellFor`](https://github.com/srid/haskell-multi-nix/blob/nixpkgs/flake.nix) under the hood.

## Documentation

https://haskell.flake.page/


## Examples

- Simple
  - https://github.com/srid/haskell-template/blob/master/flake.nix
  - https://github.com/fpindia/fpindia-site/blob/master/flake.nix
  - https://github.com/srid/haskell-multi-nix/blob/master/flake.nix (Demonstrates multiple local packages)
- Complex: 
  - https://github.com/srid/emanote/blob/master/flake.nix
  - https://github.com/srid/ema/blob/master/flake.nix

## Recommendations

- Use [`treefmt-nix`](https://github.com/numtide/treefmt-nix#flake-parts) for providing linting features like auto-formatting and hlint checks. See [haskell-template](https://github.com/srid/haskell-template) for example.

