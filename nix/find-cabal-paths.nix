{ lib, ... }:

self:
# We look for a single *.cabal in project root as well as
# multiple */*.cabal. Otherwise, error out.
#
# In future, we could just read `cabal.project`. See #76.
let
  # Like pkgs.haskell.lib.haskellPathsInDir' but with a few differences
  # - Allows top-level .cabal files
  haskellPathsInDir' = path:
    lib.filterAttrs (k: v: v != null) (lib.mapAttrs'
      (k: v:
        if v == "regular" && lib.strings.hasSuffix ".cabal" k
        then lib.nameValuePair (lib.strings.removeSuffix ".cabal" k) path
        else
          if v == "directory" && builtins.pathExists (path + "/${k}/${k}.cabal")
          then lib.nameValuePair k (path + "/${k}")
          else lib.nameValuePair k null
      )
      (builtins.readDir path));
  errorNoDefault = msg:
    builtins.throw '' 
      haskell-flake: A default value for `packages` cannot be auto-detected:

        ${msg}
      You must manually specify the `packages` option.
    '';
  cabalPaths =
    let
      cabalPaths = haskellPathsInDir' self;
    in
    if cabalPaths == { }
    then
      errorNoDefault ''
        No .cabal file found in project root or its sub-directories.
      ''
    else cabalPaths;
in
cabalPaths

