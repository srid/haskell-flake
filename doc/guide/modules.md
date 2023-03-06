---
slug: modules
---

# Project modules

haskell-flake's per-project configuration can be modularized and shared among multiple repos. This is done using the `flake.haskellFlakeProjectModules` flake output. 

Let's say you have two repositories -- `common` and `myapp`. The `common` repository may expose some shared haskell-flake settings as follows:

```nix
{
  # Inside flake-parts' `mkFlake`:
  flake.haskellFlakeProjectModules.default = { pkgs, ... }: {
    devShell.tools = hp: {
      inherit (hp) 
        hlint
        cabal-fmt
        ormolu;
    };
    source-overrides = {
      mylib = inputs.mylib;
    };
  };
}
```

This module can then be imported in multiple projects, such as the `myapp` project:

```nix
{
  # Inside flake-parts' `perSystem`:
  haskellProjects.default = {
    imports = [
      inputs.common.haskellFlakeProjectModules.default
    ];
    packages = {
      myapp.root = ./.;
    };
  };
}
```

This way your `app` project knows how to find "mylib" library as well as includes the default tools you want to use in the dev shell.

## Module arguments

A haskell-flake project module takes the following arguments:

| Argument | Description |
| --- | --- |
| `pkgs` | The perSystem's `pkgs` argument |
| `self` | The flake's `self` |

## Default modules

By default, haskell-flake will generate the following modules for the "default" `haskellProject`:

| Module | Contents |
| -- | -- |
| `haskellFlakeProjectModules.input` | Dependency overrides only |
| `haskellFlakeProjectModules.local` | Local packages only |
| `haskellFlakeProjectModules.output` | Local packages & dependency overrides |

The idea here being that you can "connect" two Haskell projects such that they depend on one another while reusing the overrides from one place. For example, if you have a project "foo" that depends on "bar" and if "foo"'s flake.nix has "bar" as its input, then in "foo"'s `haskellProject.default` entry you can import "bar" as follows:

```nix
# foo's flake.nix's perSystem
{ 
  haskellProjects.default = {
    imports = [
      inputs.bar.haskellFlakeProjectModules.output
    ];
    packages = {
      foo.root = ./.;
    };
  };
}
```

By importing "bar"'s `output` project module, you automatically get the overrides from "bar" (unless you use the `local` module) as well as the local packages[^bar]. This way you don't have to duplicate the `overrides` and manually specify the `source-overrides` in "foo"'s flake.nix.

[^bar]: Local packages come from the `packages` option. So this is typically the "bar" package itself for single-package projects; or all the local projects if it is a multi-package project.

## Examples

- https://github.com/srid/nixpkgs-140774-workaround
- https://github.com/juspay/prometheus-haskell/pull/3
