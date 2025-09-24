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
rec {
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
          (parsec.choice
            [
              (parsec.between spaces1 newline path)
              (parsec.between spaces1 parsec.eof path)
            ]);
      parser = parsec.skipThen
        key
        val;
    in
    parsec.runParser parser cabalProjectFile;

  # Extract all stanzas from a .cabal file in a single pass using choice
  # Returns an attribute set mapping stanza type to list of names
  parseCabalStanzas = cabalFile:
    with parsec;
    let
      # Parse either a stanza line or skip irrelevant line
      parseLineOrSkip = parsec.choice [
        # Try to parse a stanza line
        (parsec.fmap
          (result: {
            type = lib.head result;
            name = lib.removePrefix " " (lib.elemAt result 1);
          })
          (parsec.sequence [
            (parsec.choice [
              (parsec.string "executable")
              (parsec.string "test-suite")
              (parsec.string "benchmark")
              (parsec.string "foreign-library")
              (parsec.string "custom-setup")
              (parsec.string "library")
            ])
            (parsec.fmap lib.concatStrings (parsec.many (parsec.anyCharBut "\n")))
          ]))
        # Or skip this line
        (parsec.fmap
          (_: null)
          (parsec.sequence [ (parsec.many (parsec.anyCharBut "\n")) anyChar ]))
      ];

      # Parse many lines, keeping only stanzas (non-null results)
      parser = parsec.fmap
        (lib.filter (x: x != null))
        (parsec.many parseLineOrSkip);

      result = parsec.runParser parser cabalFile;
    in
    if result.type == "success" then
      let
        # Group stanzas by type, filtering out empty names  
        groupedStanzas = lib.foldl
          (acc: stanza:
            let
              shouldInclude = stanza.name != "";
            in
            if shouldInclude then
              acc // {
                ${stanza.type} = (acc.${stanza.type} or [ ]) ++ [ stanza.name ];
              }
            else
              acc)
          { }
          result.value;
      in
      {
        type = "success";
        value = groupedStanzas;
      }
    else
      result;

  # Extract all the executables from a .cabal file 
  parseCabalExecutableNames = cabalFile:
    let
      result = parseCabalStanzas cabalFile;
    in
    if result.type == "success"
    then {
      type = "success";
      value = result.value.executable or [ ];
    }
    else {
      type = "error";
      value = result.value;
    };
}
