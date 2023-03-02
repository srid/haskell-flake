---
slug: package-set
---

# Creating package sets

While haskell-flake is generally used to develop and build individual Haskell projects, you can also use it to create a custom Haskell packaage set that you can use in other projects. This is useful if you want to create a common package set to be shared across multiple projects.

A "project" in haskell-flake primarily serves the purpose of developing Haskell projects. Additionally, a project also exposes the final *package set* via the readonly option `outputs.finalPackages`. This package set includes the base packages (`basePackages`), the local packages as well as any [[dependency|dependency overrides]] you set. Since we are are only interested in creating a new package set, we can use empty local packages and disable the dev shell:

```nix
{
  haskellProjects.ghc810 = {
    packages = {};  # No local packages
    devShell.enable = false;

    # Start from nixpkgs's ghc8107 package set
    basePackages = pkgs.haskell.packages.ghc8107;
  };
}
```

You can access this package set as `config.haskellProjects.ghc810.outputs.finalPackages`. But this is not terribly interesting, because it is the exact same as the package set `pkgs.haskell.packages.ghc8107` from nixpkgs. So let's add and override some packages in this set:

```nix
{
  haskellProjects.ghc810 = {
    packages = {};  # No local packages
    devShell.enable = false;

    basePackages = pkgs.haskell.packages.ghc8107;

    source-overrides = {
      # New packages from flake inputs
      mylib = inputs.mylib;
      # Dependencies from Hackage
      aeson = "1.5.6.0";
      dhall = "1.35.0";
    };
    overrides = self: super: with pkgs.haskell.lib; {
       aeson = doJailbreak super.aeson;
    };
  };
}
```

This will create a package set that overrides the `aeson` and `dhall` packages using the specified versions from Hackage, but with the `aeson` package having the `doJailbreak` flag set (which relaxes its Cabal constraints).  It also adds the `mylib` package which exists neither in nixpkgs nor in Hackage, but comes from somewhere arbitrary and specified as flake input.

In your *actual* haskell project, you can use this package set (`config.haskellProjects.ghc810.outputs.finalPackages`) as its base package set:

```nix
{
  haskellProjects.myproject = {
    packages.mypackage = ./.;

    basePackages = config.haskellProjects.ghc810.outputs.finalPackages;
  };
}
```

Finally you can externalized this `ghc810` package set as either a flake-parts module or as a [[modules|haskell-flake module]], and import it in multiple repositories.

## Examples

- https://github.com/nammayatri/common/pull/3/files
