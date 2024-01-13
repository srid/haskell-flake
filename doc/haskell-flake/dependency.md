---
order: -10
---

# Overriding dependencies

Haskell libraries ultimately come from [Hackage](https://hackage.haskell.org/), and [nixpkgs] contains [most of these](https://nixpkgs.haskell.page/). Adding a library to your project involves modifying the `.cabal` file and restarting the nix shell. The process is typically as follows:

1. Identify the package name from Hackage. Let's say you want to use [`ema`](https://hackage.haskell.org/package/ema)
2. Add the package, `ema`, to the `.cabal` file under [the `build-depends` section](https://cabal.readthedocs.io/en/3.4/cabal-package.html#pkg-field-build-depends).
3. Exit and restart the nix shell (`nix develop`). 

Step (3) above will try to fetch the package from the Haskell package set in [nixpkgs] (`pkgs.haskellPackages` by default). For various reasons, this package may be either missing or marked as "broken". In such cases, you will have to override the package locally in the project (see the next section).

## Overriding a Haskell package source {#source}

In Nix, it is possible to use an exact package built from an arbitrary source - which can be a Git repo, local directory or a Hackage version. 

### Using a Git repo {#path}

If you want to use the `master` branch of the [ema](https://hackage.haskell.org/package/ema) library, for instance, you can do it as follows:

1. Add a flake input pointing to the ema Git repo in `flake.nix`: 
    ```nix
    {
      inputs = {
        ema.url = "github:srid/ema";
        ema.flake = false;
      };
    }
    ```
1. Build it using `callCabal2nix` and assign it to the `ema` name in the Haskell package set by adding it to the `packages` argument of your `flake.nix` that is using haskell-flake:
    ```nix
    {
      perSystem = { self', config, pkgs, ... }: {
        haskellProjects.default = {
          packages = {
            ema.source = inputs.ema;
          };
        };
      };
    }
    ```
1. Re-run the nix shell (`nix develop`).

### Using a Hackage version {#hackage}

`packages.<name>.source` also supports Hackage versions. So the following works to pull [ema 0.8.2.0](https://hackage.haskell.org/package/ema-0.8.2.0):

```nix
{
  perSystem = { self', config, pkgs, ... }: {
    haskellProjects.default = {
      packages = {
        ema.source = "0.8.2.0";
      };
    };
  };
}
```

### Using a nixpkgs version {#nixpkgs}

```nix
haskellProjects.default = {
  settings = {
    fourmolu = { super, ...}: { custom = _: super.fourmolu_0_13_1_0; };
  };
};
```

## Overriding a Haskell package settings {#settings}

```nix
haskellProjects.default = {
  settings = {
    ema = {  # This module can take `{self, super, ...}` args, optionally.
      # Disable running tests
      check = false;

      # Disable building haddock (documentation)
      haddock = false;

      # Ignore Cabal version constraints
      jailbreak = true;

      # Extra non-Haskell dependencies
      extraBuildDepends = [ pkgs.stork ];

      # Source patches
      patches = [ ./patches/ema-bug-fix.patch ];

      # Enable/disable Cabal flags
      cabalFlags.with-generics = true;

      # Allow building a package marked as "broken"
      broken = false;
    };
  };
};
```

:::info Note
### [nixpkgs] functions

- The `pkgs.haskell.lib` module provides various utility functions that you can use to override Haskell packages. The canonical place to find documentation on these is [the source](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix). haskell-flake provides a `settings` submodule for convienience. For eg., the `dontCheck` function translates to `settings.<name>.check`; the full list of options can be seen [here](https://github.com/srid/haskell-flake/blob/master/nix/modules/project/settings/all.nix).
:::

## Sharing settings {#settings-share}

[[modules]] export both `packages` and `settings` options for reuse in downstream Haskell projects.

## Examples

- [Emanote overrides](https://github.com/srid/emanote/commit/5b24bd04f94e03afe66ee01da723e4a05d854953): also demonstrates how to add a *new* setting option (`removeReferencesTo`).



[nixpkgs]: https://zero-to-nix.com/concepts/nixpkgs
