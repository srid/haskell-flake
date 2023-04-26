# Like callCabal2nix, but does more:
# - Source filtering (to prevent parent content changes causing rebuilds)
# - Always build from cabal's sdist for release-worthiness
# - Enables separate bin output for executables
{ pkgs, lib, self, hasExecutable, ... }:

let
  hlib = pkgs.haskell.lib.compose;

  fromSdist = self.buildFromCabalSdist or (builtins.trace "Your version of Nixpkgs does not support hs.buildFromCabalSdist yet." (pkg: pkg));

  makeSrcAutonomous = name: root: pkg: hlib.overrideSrc
    {
      src =
        # Since 'root' may be a subdirectory of a store path
        # (in string form, which means that it isn't automatically
        # copied), the purpose of cleanSourceWith here is to create a
        # new (smaller) store path that is a copy of 'root' but
        # does not contain the unrelated parent source contents.
        lib.cleanSourceWith {
          name = "source-${name}-${pkg.version}";
          src = root;
        };
    }
    pkg;
in

name: pkgCfg:
let
  pkg = self.callCabal2nix name pkgCfg.root { };
in
lib.pipe pkg
  ([
    # Avoid rebuilding because of changes in parent directories
    (makeSrcAutonomous name pkgCfg.root)

    # Make sure all files we use are included in the sdist, as a check
    # for release-worthiness.
    fromSdist

  ] ++ lib.optionals (hasExecutable name) [
    # TODO: Make it an option that the user can override
    # This is better than using justStaticExecutables, because with the later
    # builds will repeated twice!
    pkgs.haskell.lib.enableSeparateBinOutput
  ])
