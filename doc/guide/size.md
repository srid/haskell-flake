# Optimize package size

Haskell package derivations created by `haskell-flake` are shipped with symlinks to other store paths, like `$out/lib`, `$out/nix-support` and `$out/share/doc`. In addition, enabling profiling or haddock can increase the size of these packages. If your Haskell application is end-user software, you will want to strip all but the executables. This can be achieved using `justStaticExecutables`:

```nix title="flake.nix"
  # Inside perSystem
  packages.default = pkgs.haskell.lib.justStaticExecutables self'.packages.foo;
```

## Removing unnecessary Nix dependencies


There can be cases where `justStaticExecutables` doesn't work. In such cases, you can manually remove references to the store paths that you don't want to ship. Let's say you have a haskell project `foo` that is dependendent on `bar` and `bar`
relies on `data-files` in its cabal (which data-files can be, for instance, `js` or `html` files). Considering you are using `cabal-install < 3.10.1.0` the final executable of `foo` will have a reference to `bar` and `bar` will depend on `ghc`, thus increasing the overal size of the docker image. 

But how do you arrive at this point in the first place? i.e how do you pin point the exact store paths that are causing the increase in size? These are the rough steps that you can follow, if you are packaging it as part of a docker image:

- Build and scan [the docker image](/haskell-flake/docker) for store paths that are taking up the most space:
  ```bash
  nix build .#dockerImage
  docker load -i < result
  docker run --rm -it <name:tag> sh -c 'du -sh /nix/store/*' | sort -h | tail
  ```
- After the scan you will notice that `bar` will be present and its quite obvious it shouldn't be present because all of that will be packaged in the executable of `foo`. 

- It might not be obvious to you that `bar` is causing the increase in size. In such cases you can use `nix why-depends` to find out why `ghc` is present in the docker image:
  ```bash
  nix why-depends /nix/store/...-foo /nix/store/...-ghc-x.x.x
  ```

- Now that you know that `bar` is causing the increase in size, let's wrap the executable of `foo` [removing references to](https://srid.ca/remove-references-to) `bar`:
  ```nix title="flake.nix"
  {
    # Inside `haskellProjects`
    haskellProjects.default = 
      let
        # Forked from: https://github.com/srid/emanote/blob/24c7e5e29a91ec201a48fad1ac028a123b82a402/flake.nix#L52-L62
        # We shouldn't need this after https://github.com/haskell/cabal/pull/8534
        removeReferencesTo = disallowedReferences: drv:
          drv.overrideAttrs (old: rec {
            inherit disallowedReferences;
            # Ditch data dependencies that are not needed at runtime.
            # cf. https://github.com/NixOS/nixpkgs/pull/204675
            # cf. https://srid.ca/remove-references-to
            postInstall = (old.postInstall or "") + ''
              ${lib.concatStrings (map (e: "echo Removing reference to: ${e}\n") disallowedReferences)}
              ${lib.concatStrings (map (e: "remove-references-to -t ${e} $out/bin/*\n") disallowedReferences)}
            '';
          });
      in
      {
        # ...
        settings = {
          foo = {self, super, ... }: {
            justStaticExecutables = true;
            removeReferencesTo = [
              self.bar
            ];
          };
        };
        # ...
      };
  }
  ```
- Voila! Now you have a docker image that is much smaller than before.
