---
slug: dependency
---

# Adding dependencies

There are several libraries from [Hackage](https://hackage.haskell.org/) that you can use in your Haskell project nixified using haskell-flakea. The general steps to do this are:

1. Identify the package name from Hackage. Let's say you want to use [`ema`](https://hackage.haskell.org/package/ema)
2. Add the package, `ema`, to the `.cabal` file under [the `build-depends` section](https://cabal.readthedocs.io/en/3.4/cabal-package.html#pkg-field-build-depends).
3. Exit and restart the nix shell (`nix develop`). 

Step (3) above will try to fetch the package from the Haskell package set in [nixpkgs](https://github.com/NixOS/nixpkgs) (the one that is pinned in `flake.lock`), and this package set (which is ultimately derived from Stackage sets) sometimes may not have the package you are looking for. A common reason is that it is marked as "broken" or it simply doesn't exist. In such cases, you will have to override the package in the `overrides` argument (see the next section).

## Overriding a Haskell package in Nix

In Nix, it is possible to use an exact package built from an arbitrary source (Git repo or local directory). If you want to use the `master` branch of the [ema](https://hackage.haskell.org/package/ema) library, for instance, you can do it as follows:

1. Add a flake input pointing to the ema Git repo in `flake.nix`: 
    ```nix
    {
      inputs = {
        ema = {
          url = "github:EmaApps/ema";
          flake = false;
        };
      };
    }
    ```
1. Build it using `callCabal2nix` and assign it to the `ema` name in the Haskell package set by adding it to the `overrides` argument of your `flake.nix` that is using haskell-flake:
    ```nix
    {
      perSystem = { self', config, pkgs, ... }: {
        haskellProjects.default = {
          overrides = self: super: with pkgs.haskell.lib; {
            ema = dontCheck (self.callCabal2nix "ema" inputs.ema {}); 
          };
        };
      };
    }
    ```
    We use `dontCheck` here to disable running tests. You can also use `source-overrides` instead of `overrides`.
1. Re-run the nix shell (`nix develop`).

## `pkgs.haskell.lib` functions

- [ ] Write about https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix

## See also

- [Artyom's tutorial](https://tek.brick.do/how-to-override-dependency-versions-when-building-a-haskell-project-with-nix-K3VXJd8mEKO7) 