---
slug: treefmt
---

# Auto formatting using treefmt

[treefmt](https://github.com/numtide/treefmt) provides an interface to run multiple [code formatters](https://en.wikipedia.org/wiki/Prettyprint) at once, so you don't have to run them manually for each file type.

## Writing the Nix to configure treefmt in your project

### Add treefmt and flake-root to your inputs

The [`flake-root`](https://github.com/srid/flake-root) module is needed to find the root of your project based on the presence of a file, by default it is `flake.nix`. 

```nix
{
  # Inside `inputs`
  treefmt-nix.url = "github:numtide/treefmt-nix";
  flake-root.url = "github:srid/flake-root";
}
```

### Import `flakeModule` output of treefmt and flake-root

```nix
{
  # Inside outputs' `flake-parts.lib.mkFlake` 
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.flake-root.flakeModule
  ];
}
```

### Configure your formatter

To actually enable the individual formatters you want to configure treefmt. The example configuration below only consists of formatters required by a haskell project using nix. Refer to [treefmt-doc](https://numtide.github.io/treefmt/formatters/) for more formatters.

```nix
{
  # Inside mkFlake's `perSystem`
  treefmt.config = {
    inherit (config.flake-root) projectRootFile;
    # This is the default, and can be overriden.
    package = pkgs.treefmt;
    # formats .hs files (fourmolu is also available)
    programs.ormolu.enable = true;
    # formats .nix files
    programs.nixpkgs-fmt.enable = true;
    # formats .cabal files
    programs.cabal-fmt.enable = false;
    # Suggests improvements for your code in .hs files
    programs.hlint.enable = false;
  };
}
```

### Add treefmt to your devShell

Finally, add the resulting treefmt wrapper (`build.wrapper`) to your devShell. We also add the individual formatters (`build.programs`) to the devShell, so that they can be used directly in text editors and IDEs.

```nix
{
  # Inside mkFlake's `perSystem`
  haskellProjects.default = {
    devShell.tools = _: {
      treefmt = config.treefmt.build.wrapper;
    } // config.treefmt.build.programs;
  };
}
```

### Flake check

The `treefmt-nix` flake module automatically adds a flake check that can be evaluated to make sure that the project is already autoformatted.

## Tips

### Exclude folders

If there are folders where you wouldn't want to run the formatter on, use the following:

```nix
  # Inside mkFlake's `perSystem.treefmt.config`
  settings.formatter.<formatter-name>.excludes = [ "./foo/*" ];
```

### Use a different package for formatter

The package shipped with the current nixpkgs might not be the desired one, follow the snippet below to override the package (assuming `nixpkgs-21_11` is present in your flake's inputs).

```nix
  # Inside mkFlake's `perSystem.treefmt.config`
  programs.ormolu.package = nixpkgs-21_11.haskellPackages.ormolu;
```
The same can be applied to other formatters.

### Pass additional parameters to your formatter

You might want to change a certain behaviour of your formatter by overriding by passing the input to the executable. The following example shows how to pass `ghc-opt` to ormolu:

```nix
  # Inside mkFlake's `perSystem.treefmt.config`
  settings.formatter.ormolu = {
    options = [
      "--ghc-opt"
      "-XTypeApplications"
    ];
  };
```

Ormolu requires this `ghc-opt` because unlike a lot of language extensions which are enabled by default, there are some which aren't. These can be found using `ormolu --manual-exts`.

## Example

- [Sample treefmt config for your haskell project](https://github.com/srid/haskell-template/blob/a8b6d1f547d761ba392a31e644494d0eeee49c2a/flake.nix#L38-L55)

## Upcoming

- `treefmt` will provide a pre-commit mode to disable commit if formatting checks fail. This is tracked here: https://github.com/numtide/treefmt/issues/78
