---
order: -9
---

# Package Settings

Settings for individual Haskell packages can be specified in the `settings` attribute of a `haskellProjects` module. 

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

>[!info] Note
> ### [nixpkgs] functions
> 
> - The `pkgs.haskell.lib` module provides various utility functions that you can use to override Haskell packages. The canonical place to find documentation on these is [the source](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix). haskell-flake provides a `settings` submodule for convenience. For eg., the `dontCheck` function translates to `settings.<name>.check`; the full list of options can be seen [here](https://github.com/srid/haskell-flake/blob/master/nix/modules/project/settings/all.nix).

## Sharing package settings {#share}

[[modules]] export both `packages` and `settings` options for reuse in downstream Haskell projects.

## Custom settings {#custom}

- [Emanote overrides](https://github.com/srid/emanote/commit/5b24bd04f94e03afe66ee01da723e4a05d854953): demonstrates how to add a *new* setting option (`removeReferencesTo`).


[nixpkgs]: https://nixos.asia/en/nixpkgs