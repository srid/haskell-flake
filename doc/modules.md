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
    packages = {
      mylib.source = inputs.mylib;
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
| `haskellFlakeProjectModules.output` | [[local\|Local packages]] & dependency overrides |

The idea here being that you can "connect" two Haskell projects such that they depend on one another while reusing the overrides -- `packages` (see [[dependency]]) and `settings` (see [[settings]]) -- from one place. For example, if you have a project "foo" that depends on "bar" and if "foo"'s flake.nix has "bar" as its input, then in "foo"'s `haskellProject.default` entry you can import "bar" as follows:

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

By importing "bar"'s `output` project module, you automatically get the overrides from "bar" as well as the [[local|local packages]]. This way you don't have to duplicate the `settings` and manually specify the `packages.<name>.source` in "foo"'s flake.nix.

## Export non-default project modules

The flake output `haskellFlakeProjectModules.output` exports `packages` and [[settings]] options of `haskellProject.default`, but you could create custom flake output that does the same for an arbitrary project, let's say `bar`, as follows:

```nix
# Inside foo/flake.nix's outputs
{
  flake-parts.lib.mkFlake { inherit inputs; } ({ withSystem, ... }: {
    flake.haskellFlakeProjectModules = {
      bar = { pkgs, lib, ... }: withSystem pkgs.system ({ config, ... }:
        config.haskellProjects.bar.defaults.projectModules.output
      );
    };
  });
}
```

The flake output `haskellFlakeProjectModules.bar` of `foo` can be imported in another project, let's say `baz`, as:

```nix
# baz/flake.nix's perSystem
{ 
  haskellProjects.default = {
    imports = [
      inputs.foo.haskellFlakeProjectModules.bar
    ];
  };
}
```

## Examples

- https://github.com/nammayatri/nammayatri (imports `shared-kernel` which in turn imports `euler-hs`)
