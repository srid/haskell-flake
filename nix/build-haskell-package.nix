# Like callCabal2nix, but does more:
# - Source filtering (to prevent parent content changes causing rebuilds)
# - Always build from cabal's sdist for release-worthiness
{ pkgs, lib, self, ... }:

let
  fromSdist = self.buildFromCabalSdist or (builtins.trace "Your version of Nixpkgs does not support hs.buildFromCabalSdist yet." (pkg: pkg));

  mkNewStorePath = name: src:
    # Since 'src' may be a subdirectory of a store path
    # (in string form, which means that it isn't automatically
    # copied), the purpose of cleanSourceWith here is to create a
    # new (smaller) store path that is a copy of 'src' but
    # does not contain the unrelated parent source contents.
    lib.cleanSourceWith {
      name = "${name}";
      inherit src;
    };
in

name: pkgCfg:
lib.pipe pkgCfg.root
  [
    # Avoid rebuilding because of changes in parent directories
    (mkNewStorePath "source-${name}")

    (x: builtins.trace x.outPath x)

    (root: self.callCabal2nix name root { })

    # Make sure all files we use are included in the sdist, as a check
    # for release-worthiness.
    fromSdist
  ]
