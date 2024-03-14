---
order: -11
---

# Local packages

Local Haskell packages are defined in the `packages.*.source` option under `haskellProjects.<name>` module. They are automatically detected if you have a single top-level Cabal package, or multiple Cabal packages defined in a `cabal.project` file, via [[defaults|default settings]].

{#single}
## Single package

If your repository has a single top-level `.cabal` file, haskell-flake will use it by [[defaults|default]]. There is no need to specify `packages.*.source` yourself.

{#multi}
## Multiple packages

If you have multiple Haskell packages in sub-directories, you can refer to them in a `cabal.project` file to have haskell-flake automatically use them as local packages by [[defaults|default]]:

See https://github.com/srid/haskell-multi-nix for example:

```sh
$ cat cabal.project
packages:
    ./foo
    ./bar
```

The `cabal.project` file must begin with a `packages:` key, followed by a list of directories containing the cabal files.

```sh
$ ls */*.cabal
bar/bar.cabal  foo/foo.cabal
```

{#source-filtering}
## Source filtering

When a local package is in a sub-directory, haskell-flake will create a new store path to avoid changes to parent files (using [`cleanSourceWith`]) triggering a rebuild.

When a local package is the only top-level one, however, any file in the repository will by default trigger a rebuild. This is because `haskellProjects.<name>.projectRoot` is set to `self` by default. 

{#rebuild}
### Avoiding rebuild of top-level package

To avoid rebuilding the top-level package whenever irrelevant files change, you can do one of the following:

- Put the top-level package in a sub-directory.
- Or, set `projectRoot` to a subset of your flake root, [for example](https://github.com/srid/haskell-template/blob/033913a6fe418ea0c25ec2c2604ab4030563ba2e/flake.nix#L28-L34):
    ```nix
    {
      haskellProjects.default = {
        projectRoot = builtins.toString (lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.unions [
            ./src
            ./haskell-template.cabal
          ];
        });
      }
    }
    ```

[`cleanSourceWith`]: https://github.com/srid/haskell-flake/blob/67db46409b4c2e92abf27ddde7c75ae310d4068c/nix/build-haskell-package.nix#L15-L24