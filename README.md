# haskell-flake

A [`flake-parts`](https://flake.parts/) Nix module for Haskell development.

## Why?

To keep `flake.nix` smaller (eg.: going from this [91-line flake.nix](https://github.com/srid/haskell-template/blob/c082385a7fb2f4c98e59d7642090b3096a66fc51/flake.nix) to the [31-line](https://github.com/srid/haskell-template/blob/master/flake.nix) one) and declarative ([what](https://github.com/srid/emanote-template/blob/c955a08fa685adb2fb81c4d8cefac6e20f417fee/flake.nix#L19-L26) vs [how](https://github.com/srid/emanote-template/blob/78d64b6e1e3497e3bd97012d8bf6f8bd6ec9cdd3/flake.nix#L19-L57)) by bringing NixOS [module system](https://nixos.org/manual/nixos/stable/index.html#sec-writing-modules) to flakes.

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
