# Like pkgs.haskell.lib.haskellPathsInDir' but with a few differences
# - Allows top-level .cabal files
# - Recurses into subdirectories
# - Allows package.yaml files
{ lib, ... }:

path':

let
  parseCabalName = file:
    lib.strings.removeSuffix ".cabal" file;
  parseHpackName = file:
    # TODO: this is a hack, we should use a proper parser
    let
      line = builtins.head (lib.strings.split "[[:space:]]*\n[[:space:]]*" (builtins.readFile file));
      extract = xs: builtins.head (builtins.tail (builtins.tail xs));
    in
    extract (lib.strings.split "[[:space:]]*name[[:space:]]*:[[:space:]]*" line);
  f = path: lib.mapAttrsToList
    (k: v:
      let
        pass = [ ];
        one = x: [ x ];
      in
      if v == "regular"
      then
        if lib.strings.hasSuffix ".cabal" k
        then one (lib.nameValuePair (parseCabalName k) path)
        else if k == "package.yaml"
        then one (lib.nameValuePair (parseHpackName k) path)
        else pass
      else
        if v == "directory"
        then
          if builtins.pathExists (path + "/${k}/${k}.cabal")
          then
            one (lib.nameValuePair k (path + "/${k}"))
          else
            if builtins.pathExists (path + "/${k}/package.yaml")
            then one (lib.nameValuePair (parseHpackName (path + "/${k}/package.yaml")) (path + "/${k}"))
            else f (path + "/${k}")
        else pass
    )
    (builtins.readDir path);
in
lib.listToAttrs (lib.flatten (f path'))
