# Like callCabal2nix, but does more:
# - Source filtering (to prevent parent content changes causing rebuilds)
# - Always build from cabal's sdist for release-worthiness
{ pkgs, lib, self, log, ... }:

let
  fromSdist = self.buildFromCabalSdist or
    (log.traceWarning "Your nixpkgs does not have hs.buildFromCabalSdist" (pkg: pkg));

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
    (x: log.traceDebug "${name}.mkNewStorePath ${x.outPath}" x)

    (root: self.callCabal2nix name root { })
    (x: log.traceDebug "${name}.cabal2nixDeriver ${x.cabal2nixDeriver.outPath}" x)

    # Make sure all files we use are included in the sdist, as a check
    # for release-worthiness.
    fromSdist
    (x: log.traceDebug "${name}.fromSdist ${x.outPath}" x)
  ]
