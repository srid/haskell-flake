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
        haskellProjects.my-haskell-package {
          buildTools = hp: {
            fourmolu = hp.fourmolu;
          };
        };
      };
    };
}
```

For full example, see https://github.com/srid/haskell-template/blob/master/flake.nix
