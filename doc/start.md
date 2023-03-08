---
order: -10
---

# Getting Started

Before using `haskell-flake` you must first [[nix|install Nix with Flakes enabled]].

## Existing projects

To use `haskell-flake` in an *existing* Haskell project, run:

```sh
nix flake init -t github:srid/haskell-flake
```

Open the generated `flake.nix` and change `self'.packages.example` to use your package name. For example, if your package is named `my-package` (with a `my-package.cabal` file), change `example` to `my-package`. Follow the comments along the `flake.nix` to make any necessary changes to the project configuration.

## New projects

To create a *new* Haskell project, instead, run:

```sh
mkdir example && cd ./example
nix flake init -t github:srid/haskell-flake#example
```

### Template

You may also use https://github.com/srid/haskell-template which already uses `haskell-flake` along with other opinionated defaults.

## Next steps

Visit [[guide]] for more details, and [[ref]] for module options.