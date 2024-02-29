# Like callCabal2nix, but does more:
# - Source filtering (to prevent parent content changes causing rebuilds)
# - Always build from cabal's sdist for release-worthiness
# - Logs what it's doing (based on 'log' option)
#
{ pkgs
, lib
  # 'self' refers to the Haskell package set context.
, self
, log
, ...
}:

let
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

name: root:
lib.pipe root
  [
    # Avoid rebuilding because of changes in parent directories
    (mkNewStorePath "source-${name}")
    (x: log.traceDebug "${name}.mkNewStorePath ${x.outPath}" x)

    (root: self.callCabal2nix name root { })
    (x: log.traceDebug "${name}.cabal2nixDeriver ${x.cabal2nixDeriver.outPath}" x)
  ]
