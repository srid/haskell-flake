---
order: -10
---

# Getting Started

To use `haskell-flake` in your *existing* Haskell projects, run:

``` nix
nix flake init -t github:srid/haskell-flake
```

To create a *new* Haskell project, run:

``` nix
nix flake init -t github:srid/haskell-flake#example
```

### Template

You may also use https://github.com/srid/haskell-template which already uses `haskell-flake` along with other opinionated defaults.

Visit [[guide]] for more details, and [[ref]] for module options.