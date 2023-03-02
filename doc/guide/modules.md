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

## Examples

- https://github.com/srid/nixpkgs-140774-workaround
- https://github.com/juspay/prometheus-haskell/pull/3
