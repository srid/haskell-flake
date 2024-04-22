{ pkgs
, lib
, throwError ? builtins.throw
, throwErrorOnCabalProjectParseError ? builtins.throw
, ...
}:

let
  parser = import ./parser.nix { inherit pkgs lib; };
  traversal = rec {
    findSingleCabalFile = path:
      let
        cabalFiles = lib.filter (lib.strings.hasSuffix ".cabal") (builtins.attrNames (builtins.readDir path));
        num = builtins.length cabalFiles;
      in
      if num == 0
      then null
      else if num == 1
      then builtins.head cabalFiles
      else throwError "Expected a single .cabal file, but found multiple: ${builtins.toJSON cabalFiles}";
    getCabalName =
      lib.strings.removeSuffix ".cabal";
    findHaskellPackageNameOfDirectory = path:
      let
        cabalFile = findSingleCabalFile path;
      in
      if cabalFile != null
      then
        getCabalName cabalFile
      else
        throwError "No .cabal file found under ${path}";
  };
in
{
  findPackagesInCabalProject = projectRoot:
    let
      cabalProjectFile = projectRoot + "/cabal.project";
      packageDirs =
        if builtins.pathExists cabalProjectFile
        then
          let
            res = parser.parseCabalProjectPackages (builtins.readFile cabalProjectFile);
            isSelfPath = path:
              path == "." || path == "./" || path == "./.";
          in
          if res.type == "success"
          then
            map
              (path:
                if isSelfPath path
                then projectRoot
                else if lib.strings.hasInfix "*" path
                then throwErrorOnCabalProjectParseError "Found a path with glob (${path}) in ${cabalProjectFile}, which is not supported"
                else if lib.strings.hasSuffix ".cabal" path
                then throwErrorOnCabalProjectParseError "Expected a directory but ${path} (in ${cabalProjectFile}) is a .cabal filepath"
                else "${projectRoot}/${path}"
              )
              res.value
          else throwErrorOnCabalProjectParseError "Failed to parse ${cabalProjectFile}: ${builtins.toJSON res}"
        else
          [ projectRoot ];
    in
    lib.listToAttrs
      (map
        (path:
          lib.nameValuePair (traversal.findHaskellPackageNameOfDirectory path) path)
        packageDirs);

  getCabalExecutables = path:
    let
      cabalFile = traversal.findSingleCabalFile path;
    in
    if cabalFile != null then
      let res = parser.parseCabalExecutableNames (builtins.readFile (lib.concatStrings [ path "/" cabalFile ]));
      in
      if res.type == "success"
      then res.value
      else throwError "Failed to parse ${cabalFile}: ${builtins.toJSON res}"
    else
      throwError "No .cabal file found under ${path}";
}
