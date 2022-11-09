# haskell-flake

A [`flake-parts`](https://flake.parts/) Nix module for Haskell development.

## Why?

To keep `flake.nix` smaller (see examples below) and declarative ([what](https://github.com/srid/emanote-template/blob/c955a08fa685adb2fb81c4d8cefac6e20f417fee/flake.nix#L19-L26) vs [how](https://github.com/srid/emanote-template/blob/78d64b6e1e3497e3bd97012d8bf6f8bd6ec9cdd3/flake.nix#L19-L57)) by bringing a NixOS-like [module system](https://nixos.org/manual/nixos/stable/index.html#sec-writing-modules) to flakes (through `flake-parts`).

## Usage

To use `haskell-flake` in your Haskell projects, create a `flake.nix` containing the following:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [ inputs.haskell-flake.flakeModule ];
      perSystem = { self', pkgs, ... }: {
        haskellProjects.default = {
          packages = { 
            # You can add more than one local package here.
            my-package.root = ./.;  # Assumes ./my-package.cabal
          };
          # buildTools = hp: { fourmolu = hp.fourmolu; ghcid = null; };
          # overrides = self: super: { };
          # hlintCheck.enable = true;
          # hlsCheck.enable = true;
        };
        # haskell-flake doesn't set the default package, but you can do it here.
        packages.default = self'.packages.my-package;
      };
    };
}
```

See [`flake-module.nix` -> `options`](flake-module.nix) for a list of options available. `haskell-flake` uses `callCabal2nix` and `shellFor` [under the hood](https://github.com/srid/haskell-multi-nix/blob/master/flake.nix).

## Template

If you are bootstrapping a *new* Haskell project, you may use https://github.com/srid/haskell-template which already uses `haskell-flake`.

## Examples

- Simple
  - https://github.com/srid/haskell-template/blob/master/flake.nix
  - https://github.com/fpindia/fpindia-site/blob/master/flake.nix
  - https://github.com/srid/haskell-multi-nix/blob/master/flake.nix (Demonstrates multiple local packages)
- Complex: 
  - https://github.com/srid/emanote/blob/master/flake.nix
  - https://github.com/srid/ema/blob/master/flake.nix
