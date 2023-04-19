# Sufficiently basic parsers for `cabal.project` and `package.yaml` formats
#
# "sufficiently" because we care only about 'packages' from `cabal.project` and
# 'name' from `package.yaml`.
{ lib, ... }:

let
  nix-parsec = builtins.fetchGit {
    url = "https://github.com/kanwren/nix-parsec.git";
    ref = "master";
    rev = "1bf25dd9c5de1257a1c67de3c81c96d05e8beb5e";
    shallow = true;
  };
  inherit (import nix-parsec) parsec;
in
{
  # Extract the "packages" list from a cabal.project file.
  #
  # Globs are not supported yet. Values must be refer to a directory, not file.
  parseCabalProjectPackages = cabalProjectFile:
    let
      spaces1 = parsec.skipWhile1 (c: c == " " || c == "\t");
      newline = parsec.string "\n";
      path = parsec.fmap lib.concatStrings (parsec.many1 (parsec.anyCharBut "\n"));
      key = parsec.string "packages:\n";
      val =
        parsec.many1
          (parsec.between spaces1 newline path);
      parser = parsec.skipThen
        key
        val;
    in
    parsec.runParser parser cabalProjectFile;

  # Extract the "name" field from a package.yaml file.
  parsePackageYamlName = packageYamlFile:
    let
      spaces1 = parsec.skipWhile1 (c: c == " " || c == "\t");
      key = parsec.string "name:";
      val = parsec.fmap lib.concatStrings (parsec.many1 (parsec.anyCharBut "\n"));
      parser = parsec.skipThen
        (parsec.skipThen key spaces1)
        val;
    in
    parsec.runParser parser packageYamlFile;

  # Extract all the executables from a .cabal file 
  parseCabalExecutableNames = cabalFile:
    with parsec;
    let
      # Skip empty lines and lines that don't start with 'executable'
      skipLines =
        skipTill
          (sequence [ (skipWhile (x: x != "\n")) anyChar ])
          (parsec.string "executable ");
      val = parsec.fmap lib.concatStrings (parsec.many1 (parsec.anyCharBut "\n"));
      parser = parsec.many (parsec.skipThen
        skipLines
        val);
    in
    parsec.runParser parser cabalFile;
}
