# haskell-flake

A [`flake-parts`](https://flake.parts/) module to make Haskell development [simpler](https://haskell.flake.page/start#under-the-hood) with Nix.

<img src="./doc/logo.webp" width=100 />

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

