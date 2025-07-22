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

> [!info] Note
>
> ### [nixpkgs] functions
>
> - The `pkgs.haskell.lib` module provides various utility functions that you can use to override Haskell packages. The canonical place to find documentation on these is [the source](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix). haskell-flake provides a `settings` submodule for convenience. For eg., the `dontCheck` function translates to `settings.<name>.check`; the full list of options can be seen [here](https://github.com/srid/haskell-flake/blob/master/nix/modules/project/settings/all.nix).

## Sharing package settings {#share}

[[modules]] export both `packages` and `settings` options for reuse in downstream Haskell projects.

## Custom settings {#custom}

You can provide custom settings for use in multiple packages (even across multiple repos). For example, see [this Emanote change](https://github.com/srid/emanote/commit/5b24bd04f94e03afe66ee01da723e4a05d854953) which demonstrates how to add a _new_ setting option (`removeReferencesTo`).

## Extra settings {#extra}

haskell-flake provides the following settings on top of those provided by [nixpkgs].

### `generateOptparseApplicativeCompletions`

Generate and install shell completion files for executables.
The executables need to be using `optparse-applicative` for this to work.
Note that this feature is automatically disabled when cross-compiling, since it requires executing the binaries in question.

### `removeReferencesTo`

Remove references to other packages from this Haskell package. This is useful to eliminate unnecessary data dependencies from your Haskell executable so as to reduce its closure size.

> [!info] For more, see
>
> - https://github.com/NixOS/nixpkgs/pull/204675
> - https://srid.ca/remove-references-to

### `buildFromSdist`

Newer versions of [nixpkgs] provide `buildFromSdist` to build your package from the `cabal sdist` tarball. This is enabled by default, to help with checking release-worthiness of your packages.

> [!warning] Issues with `buildFromSdist`
> If you encounter issues with `buildFromSdist` you can disable it by setting `settings.<name>.buildFromSdist` to `true`.

[nixpkgs]: https://nixos.asia/en/nixpkgs

### `stan`

Run **ST**atic **AN**alysis on the package using [stan] and generate an HTML report. The report is created in the `/nix/store` path alongside your package outputs.

> [!note] stan configuration  
> This setting looks for a `.stan.toml` file in the root of the package source. See a sample [.stan.toml] configuration for reference.

[stan]: https://github.com/kowainik/stan
[.stan.toml]: https://github.com/kowainik/stan/blob/main/.stan.toml
