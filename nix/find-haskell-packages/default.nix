{ pkgs
, lib
, throwError ? msg: builtins.throw msg
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
    findSinglePackageYamlFile = path:
      let f = path + "/package.yaml";
      in if builtins.pathExists f then f else null;
    getCabalName = cabalFile:
      lib.strings.removeSuffix ".cabal" cabalFile;
    getPackageYamlName = fp:
      let
        name = parser.parsePackageYamlName (builtins.readFile fp);
      in
      if name.type == "success"
      then name.value
      else throwError ("Failed to parse ${fp}: ${builtins.toJSON name}");
    findHaskellPackageNameOfDirectory = path:
      let
        cabalFile = findSingleCabalFile path;
        packageYamlFile = findSinglePackageYamlFile path;
      in
      if cabalFile != null
      then
        getCabalName cabalFile
      else if packageYamlFile != null
      then
        getPackageYamlName packageYamlFile
      else
        throwError "Neither a .cabal file nor a package.yaml found under ${path}";
  };
in
projectRoot:
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
            then throwError "Found a path with glob (${path}) in ${cabalProjectFile}, which is not supported"
            else if lib.strings.hasSuffix ".cabal" path
            then throwError "Expected a directory but ${path} (in ${cabalProjectFile}) is a .cabal filepath"
            else "${projectRoot}/${path}"
          )
          res.value
      else throwError ("Failed to parse ${cabalProjectFile}: ${builtins.toJSON res}")
    else
      [ projectRoot ];
  packageExecutables = path:
    let
      cabalFile = traversal.findSingleCabalFile path;
      res = parser.parseCabalExecutableNames (builtins.readFile (lib.concatStrings [ path "/" cabalFile ]));
    in
    if res.type == "success"
    then res.value
    else throwError ("Failed to parse ${cabalFile}: ${builtins.toJSON res}");
in
lib.listToAttrs
  (map
    (path:
    lib.nameValuePair (traversal.findHaskellPackageNameOfDirectory path) ({ inherit path; executables = packageExecutables path; }))
    packageDirs)
