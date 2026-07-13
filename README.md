# haskell-flake - Ergonomic Nix module for Haskell development

<img src="./doc/haskell-flake.webp" width=100 />

There are [several ways](https://nixos.asia/en/haskell) to manage Haskell packages using [Nix](https://nixos.asia/en/nix) with varying degrees of integration. `haskell-flake` makes Haskell development, packaging and deployment with Nix a lot [simpler](https://haskell.nixos.asia/start#under-the-hood) than other existing approaches. It works with plain Nix (no flakes), Nix flakes, or as a [`flake-parts`](https://flake.parts/) module—choose whichever fits your project.

To see more background information, guides and best practices, visit https://haskell.nixos.asia

Caveat: `haskell-flake` only supports the Haskell package manager [Cabal](https://www.haskell.org/cabal/),
so your project must have a top-level `.cabal` file (single package project) or a `cabal.project` file
(multi-package project).

## Getting started

The guide below uses [flake-parts](https://flake.parts/); for other approaches see [standalone usage](https://haskell.nixos.asia/standalone).

The minimal changes to your `flake.nix` to introduce `haskell-flake` with flake-parts will look similar to:

```nix
# file: flake.nix
{
  inputs = {
    ...
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux", ... ];
      imports = [
        ...
        inputs.haskell-flake.flakeModule
      ];
      perSystem = { self', system, lib, config, pkgs, ... }: {
        haskellProjects.default = {
          # basePackages = pkgs.haskellPackages;

          # Packages to add on top of `basePackages`, e.g. from Hackage
          packages = {
            aeson.source = "1.5.0.0"; # Hackage version
          };

          # my-haskell-package development shell configuration
          devShell = {
            hlsCheck.enable = false;
          };

          # What should haskell-flake add to flake outputs?
          autoWire = [ "packages" "apps" "checks" ]; # Wire all but the devShell
        };

        devShells.default = pkgs.mkShell {
          name = "my-haskell-package custom development shell";
          inputsFrom = [
            ...
            config.haskellProjects.default.outputs.devShell
          ];
          nativeBuildInputs = with pkgs; [
            # other development tools.
          ];
        };
      };
    };
}
```

`haskell-flake` scans your folder automatically for a `.cabal` or `cabal.project` file.
In this example an imaginary `my-haskell-package.cabal` project is used.

To see in more detail how to use `haskell-flake` in a realistic Haskell project
with several other development tools, take a look at
the corresponding [Haskell single-package project Nix template](https://github.com/srid/haskell-template) and
this [Haskell multi-package project Nix example](https://github.com/srid/haskell-multi-nix).

## Documentation

https://haskell.nixos.asia

## Discussion

Please post questions & ideas in [Github Discussions](https://github.com/srid/haskell-flake/discussions).
