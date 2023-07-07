---
slug: /haskell-flake/devshell
---

# DevShell

haskell-flake uses the [`shellFor`][shellFor] function to provide a Haskell development shell. `shellFor` in turn uses the standard [`mkShell`][mkShell] function to create a Nix shell environment. The `mkShellArgs` option can be used to pass custom arguments to `mkShell`.

```nix
{
  haskellProjects.default = {
    devShell = {
      mkShellArgs = {
        shellHook = ''
          export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pkgs.flint}/lib
        ''
      };
    }
  }
}
```

## Composing devShells

While `mkShellArgs` is a convenient way to extend the Haskell devShell, sometimes you want to compose multiple devShell environments in a way you want.

The devShell of a haskell-flake project is exposed in the `config.haskellProjects.<name>.outputs.devShell` attribute. You can pass this devShell to the `inputsFrom` argument of a [`mkShell`][mkShell] function in order to include the Haskell devShell in another devShell. The same technique can be used to compose devShells created by other flake-parts modules. 

For example, [in haskell-template](https://github.com/srid/haskell-template/blob/fc263b19e4ef02710ffc61fc656aec6c1a873974/flake.nix#L96-L102), we create a top-level devShell that merges the devShell of the haskell-flake project, the devShell of [mission-control](https://github.com/Platonic-Systems/mission-control) and the devShell of [flake-root](https://github.com/srid/flake-root) as follows::

```nix
{
  devShell = pkgs.mkShell {
    inputsFrom = [
      config.haskellProjects.default.outputs.devShell
      config.flake-root.devShell
      config.mission-control.devShell
    ];
  };
}
```

This sort of composition is either impossible or very complex to do with the `mkShellArgs` approach.


[shellFor]: https://nixos.org/manual/nixpkgs/unstable/#haskell-shellFor
[mkShell]: https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell

