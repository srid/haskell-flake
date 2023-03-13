# Like callCabal2nix, but does more:
# - Recognizes projects with only package.yaml
# - Source filtering (to prevent parent content changes causing rebuilds)
{ pkgs, lib, self, ... }:

let
  hlib = pkgs.haskell.lib.compose;

  fromSdist = self.buildFromCabalSdist or (builtins.trace "Your version of Nixpkgs does not support hs.buildFromCabalSdist yet." (pkg: pkg));

  # If `root` has package.yaml, but no cabal file, generate the cabal
  # file and return the new source tree.
  realiseHpack = name: root:
    let
      contents = lib.attrNames (builtins.readDir root);
      hasCabal = lib.any (lib.strings.hasSuffix ".cabal") contents;
      hasHpack = builtins.elem ("package.yaml") contents;
    in
    if (!hasCabal && hasHpack)
    then
      pkgs.runCommand
        "${name}-hpack"
        { nativeBuildInputs = [ pkgs.hpack ]; }
        ''
          cp -r ${root} $out
          chmod u+w $out
          cd $out
          hpack
        ''
    else root;

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
  # NOTE: Even though cabal2nix does run hpack automatically,
  # buildFromCabalSdist does not. So we must run hpack ourselves at
  # the original source level.
  root = realiseHpack name pkgCfg.root;
  pkg = self.callCabal2nix name root { };
in
lib.pipe pkg
  [
    # Avoid rebuilding because of changes in parent directories
    (makeSrcAutonomous name root)

    # Make sure all files we use are included in the sdist, as a check
    # for release-worthiness.
    fromSdist
  ]
