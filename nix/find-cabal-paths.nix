{ pkgs, lib, ... }:

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
      else builtins.throw "Multiple cabal files found";
    findSinglePackageYamlFile = path:
      let f = path + "/package.yaml";
      in if builtins.pathExists f then f else null;
    getCabalName = cabalFile:
      lib.strings.removeSuffix ".cabal" cabalFile;
    getPackageYamlName = fp:
      let
        name = parser.parsePackageYamlName fp;
      in
      if name.type == "success"
      then name.value
      else builtins.throw (builtins.toJSON name);
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
        builtins.throw "Neither a .cabal file nor a package.yaml found under ${path}";
  };
in
self:
let
  cabalProjectFile = self + "/cabal.project";
  packageDirs =
    if builtins.pathExists cabalProjectFile
    then
      let
        res = parser.parseCabalProjectPackages (builtins.readFile cabalProjectFile);
        isSelfPath = path:
          path == "." || path == "./" || path == "./.";
      in
      if res.type == "success"
      then map (path: if isSelfPath path then self else "${self}/${path}") res.value
      else builtins.throw (builtins.toJSON res)
    else
      [ self ];
in
lib.listToAttrs
  (map
    (path:
    lib.nameValuePair (traversal.findHaskellPackageNameOfDirectory path) path)
    packageDirs)
