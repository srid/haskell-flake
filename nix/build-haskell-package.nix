# Like callCabal2nix, but does more:
# - Source filtering (to prevent parent content changes causing rebuilds)
# - Always build from cabal's sdist for release-worthiness
# - Enables separate bin output for executables
{ pkgs, lib, self, debug, hasExecutable, ... }:

let
  log = import ./logging.nix { inherit lib debug; };

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
  ([
    # Avoid rebuilding because of changes in parent directories
    (mkNewStorePath "source-${name}")
    (log.traceDebug "${name}.mkNewStorePath" (x: x.outPath))

    (root: self.callCabal2nix name root { })
    (log.traceDebug "${name}.cabal2nixDeriver" (x: x.cabal2nixDeriver.outPath))

    # Make sure all files we use are included in the sdist, as a check
    # for release-worthiness.
    fromSdist
    (log.traceDebug "${name}.fromSdist" (x: x.outPath))

  ] ++ lib.optionals (hasExecutable name) [
    # TODO: Make it an option that the user can override
    # This is better than using justStaticExecutables, because with the later
    # builds will repeated twice!
    pkgs.haskell.lib.enableSeparateBinOutput
    (log.traceDebug "${name}.afterFlags" (x: x.outPath))
  ])
