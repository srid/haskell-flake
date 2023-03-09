{ pkgs, ... }:

let
  parser = pkgs.callPackage ./parser.nix { };
  cabalProjectTests = [
    {
      desc = "Simple";
      s = ''
        packages:
          foo
          bar
      '';
      r = [ "foo" "bar" ];
    }
  ];
  runParserTests = fn: spec: map
    (t:
      let
        parsed = fn t.s;
        logPrefix = "[TEST] ";
      in
      if t.r == parsed.value
      then builtins.trace (logPrefix + "[✅] " + t.desc) parsed
      else
        builtins.trace (logPrefix + "[❌] " + t.desc) (
          builtins.throw (builtins.toJSON parsed)))
    spec;
in
pkgs.writeTextFile {
  name = "parser_tests.log";
  text =
    let
      res = runParserTests parser.parseCabalProjectPackages cabalProjectTests;
    in
    "${builtins.toJSON res}";
}
