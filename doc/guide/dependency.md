---
slug: dependency
---

# Overriding dependencies

Haskell libraries ultimately come from [Hackage](https://hackage.haskell.org/), and [nixpkgs] contains [most of these](https://nixpkgs.haskell.page/). Adding a library to your project is done as follows (requiring no change to Nix!):

1. Identify the package name from Hackage. Let's say you want to use [`ema`](https://hackage.haskell.org/package/ema)
2. Add the package, `ema`, to the `.cabal` file under [the `build-depends` section](https://cabal.readthedocs.io/en/3.4/cabal-package.html#pkg-field-build-depends).
3. Exit and restart the nix shell (`nix develop`). 

Step (3) above will try to fetch the package from the Haskell package set in [nixpkgs] (the one that is pinned in `flake.lock`). For various reasons, this package may be either broken or does not exist. In such cases, you will have to override the package in the `overrides` argument (see the next section).

## Overriding a Haskell package in Nix

In Nix, it is possible to use an exact package built from an arbitrary source (Git repo or local directory). If you want to use the `master` branch of the [ema](https://hackage.haskell.org/package/ema) library, for instance, you can do it as follows:

1. Add a flake input pointing to the ema Git repo in `flake.nix`: 
    ```nix
    {
      inputs = {
        ema.url = "github:srid/ema";
        ema.flake = false;
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
    We use `dontCheck` here to disable running tests.
1. Re-run the nix shell (`nix develop`).

### [nixpkgs] functions

- The `pkgs.haskell.lib` module provides various utility functions (like `dontCheck` above, to disable running tests) that you can use to override Haskell packages. The canonical place to find documentation on these is [the source](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix).
- `self.callHackage` - Build a library from Hackage given its version. You can also do this with `source-overrides` (see below).
- [Artyom's tutorial](https://tek.brick.do/how-to-override-dependency-versions-when-building-a-haskell-project-with-nix-K3VXJd8mEKO7) 

## Using `source-overrides`

If you are only specifying the source of the Haskell package, but are not overriding anything else, you may use the simpler `source-overrides` option instead. The above example would look like:

```nix
{
  perSystem = { self', config, pkgs, ... }: {
    haskellProjects.default = {
      source-overrides = {
        ema = inputs.ema;
      };
    };
  };
}
```

`source-overrides` also supports specifying referring directly to a Hackage version. So the following works to pull [ema 0.8.2.0](https://hackage.haskell.org/package/ema-0.8.2.0):

```nix
{
  perSystem = { self', config, pkgs, ... }: {
    haskellProjects.default = {
      source-overrides = {
        ema = "0.8.2.0";
      };
    };
  };
}
```

If you are using both the options, `overrides` take priority over `source-overrides`.



[nixpkgs]: https://zero-to-nix.com/concepts/nixpkgs