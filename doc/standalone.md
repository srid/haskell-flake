---
order: 1
---

# Standalone usage (without flake-parts)

haskell-flake can be used without [flake-parts](https://flake.parts/) via the `lib.evalHaskellProject` function. This is useful if you have a plain flake or a legacy (non-flakes) Nix setup.

## Plain flake

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    haskell-flake.url = "github:srid/haskell-flake";
  };
  outputs = { self, nixpkgs, haskell-flake, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      project = (haskell-flake.lib { inherit pkgs; }).evalHaskellProject {
        projectRoot = self;
        modules = [{
          # Same options as haskellProjects.default = { ... }
          settings = {
            mypackage.haddock = false;
          };
          devShell.tools = hp: {
            inherit (hp) fourmolu;
          };
        }];
      };
    in
    {
      packages.${system}.default = project.packages.mypackage.package;
      devShells.${system}.default = project.devShell;
    };
}
```

## API

`haskell-flake.lib` is a function that takes `{ pkgs }` and returns an attribute set with:

### `evalHaskellProject`

```
{ projectRoot, name ? "default", modules ? [] } -> outputs
```

- **`projectRoot`** (required): Path to the project directory containing `.cabal` or `cabal.project` files.
- **`name`**: Project name, defaults to `"default"`.
- **`modules`**: List of modules with the same options available under `haskellProjects.<name>` in the flake-parts interface (e.g., `packages`, `settings`, `devShell`, `basePackages`, `otherOverlays`).

Returns the project outputs:

| Output | Description |
|---|---|
| `finalOverlay` | The composed Haskell overlay |
| `finalPackages` | The Haskell package set with all overlays applied |
| `packages` | Attrset of `{ package, exes }` for each local package |
| `apps` | Flake apps for each Cabal executable |
| `devShell` | Development shell derivation |
| `checks` | Flake checks (e.g., HLS check if enabled) |

## Without flakes

You can also use haskell-flake from traditional Nix (no flakes):

```nix
let
  haskell-flake = builtins.fetchTarball {
    url = "https://github.com/srid/haskell-flake/archive/master.tar.gz";
  };
  pkgs = import <nixpkgs> {};
  project = (import "${haskell-flake}/nix/lib.nix" { inherit pkgs; }).evalHaskellProject {
    projectRoot = ./.;
  };
in
  project.packages.mypackage.package
```
