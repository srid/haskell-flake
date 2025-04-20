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
  mkNewStorePath' = name: src:
    # Since 'src' may be a subdirectory of a store path
    # (in string form, which means that it isn't automatically
    # copied), the purpose of cleanSourceWith here is to create a
    # new (smaller) store path that is a copy of 'src' but
    # does not contain the unrelated parent source contents.
    lib.cleanSourceWith {
      name = "${name}";
      inherit src;
    };

  # Avoid rebuilding because of changes in parent directories
  mkNewStorePath = name: src:
    let newSrc = mkNewStorePath' name src;
    in log.traceDebug "${name}.mkNewStorePath ${newSrc}" newSrc;

  callCabal2nix = name: src: opts:
    let pkg = self.callCabal2nixWithOptions name src { extraCabal2nixOptions = opts; } { };
    in log.traceDebug "${name}.callCabal2nixWithOptions src=${src} deriver=${pkg.cabal2nixDeriver.outPath} opts=${opts}" pkg;

  # Use cached cabal2nix generated nix expression if present, otherwise use IFD (callCabal2nix)
  callCabal2NixUnlessCached = name: src: cabal2nixFile: opts:
    let path = "${src}/${cabal2nixFile}";
    in
    if builtins.pathExists path
    then
      callPackage name path
    else
      callCabal2nix name src opts;

  callPackage = name: nixFilePath:
    let pkg = self.callPackage nixFilePath { };
    in log.traceDebug "${name}.callPackage[cabal2nix] ${nixFilePath}" pkg;

  callHackage = name: version:
    let pkg = self.callHackage name version { };
    in log.traceDebug "${name}.callHackage ver=${version}" pkg;
in

name: cfg:
# If 'source' is a path, we treat it as such. Otherwise, we assume it's a version (from hackage).
if lib.types.path.check cfg.source
then
  callCabal2NixUnlessCached name (mkNewStorePath name cfg.source) cfg.cabal2NixFile cfg.extraCabal2nixOptions
else
  callHackage name cfg.source
