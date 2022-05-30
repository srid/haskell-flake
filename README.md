# haskell-flake

A [`flake-parts`](https://flake.parts/) Nix module for Haskell development.

## Usage

```nix
{
  outputs = { self, nixpkgs, flake-parts, haskell-flake, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        haskell-flake.flakeModule
      ];
      perSystem = { self', pkgs, ... }: {
        haskellProjects.default = {
          root = ./.;
          buildTools = hp: {
            fourmolu = hp.fourmolu;
          };
        };
      };
    };
}
```

See [`flake-module.nix` -> `options`](flake-module.nix) for a list of options available. Uses [`developPackage`](https://github.com/NixOS/nixpkgs/blob/f1c167688a6f81f4a51ab542e5f476c8c595e457/pkgs/development/haskell-modules/make-package-set.nix#L245) under the hood, but see [#7](https://github.com/srid/haskell-flake/issues/7) for future improvements.

## Template

https://github.com/srid/haskell-template

## Examples

- Simple: https://github.com/srid/haskell-template/blob/master/flake.nix
- Complex: https://github.com/srid/emanote/blob/master/flake.nix
