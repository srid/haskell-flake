{ pkgs, lib, parsec, ... }:

{
  # Extract the "packages" list from a cabal.project file.
  parseCabalProjectPackages = cabalProjectFile:
    let
      spaces1 = parsec.skipWhile1 (c: c == " " || c == "\t");
      newline = parsec.string "\n";
      path = parsec.fmap lib.concatStrings (parsec.many1 (parsec.anyCharBut "\n"));
      h = parsec.string "packages:\n";
      b =
        (parsec.many1
          (parsec.between spaces1 newline path)
        );
      p = parsec.skipThen
        h
        b;
    in
    parsec.runParser p cabalProjectFile;

  # Extract the "name" field from a package.yaml file.
  parsePackageYamlName = packageYamlFile:
    let
      spaces1 = parsec.skipWhile1 (c: c == " " || c == "\t");
      name = parsec.fmap lib.concatStrings (parsec.many1 (parsec.anyCharBut "\n"));
      h = parsec.string "name:";
      b = parsec.skipThen
        (parsec.skipThen h spaces1)
        name;
    in
    parsec.runParser b (builtins.readFile packageYamlFile);
}
