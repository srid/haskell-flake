# Run this using 'nixci' at top-level
{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib, ... }:

let
  parser = pkgs.callPackage ./parser.nix { };
  cabalProjectTests =
    let
      eval = s:
        let res = parser.parseCabalProjectPackages s; in
        if res.type == "success" then res.value else res;
    in
    {
      testSimple = {
        expr = eval ''
          packages:
            foo
            bar
        '';
        expected = [ "foo" "bar" ];
      };

      # Handles cases where cabal.project does not end with newline
      testEOF = {
        expr = eval ''
          packages:
            foo
            bar'';
        expected = [ "foo" "bar" ];
      };
    };
  cabalExecutableTests =
    let
      eval = s:
        let res = parser.parseCabalExecutableNames s; in
        if res.type == "success" then res.value else res;
    in
    {
      testSimple = {
        expr = eval ''
          cabal-version: 3.0
          name: test-package
          version: 0.1

          executable foo-exec
            main-is: foo.hs

          library test
            exposed-modules: Test.Types

          executable bar-exec
            main-is: bar.hs
        '';
        expected = [ "foo-exec" "bar-exec" ];
      };
    };
  cabalStanzasTests =
    let
      eval = s:
        let
          res = parser.parseCabalStanzas s;
        in
        if res.type == "success" then res.value else res;
    in
    {
      testMultipleStanzas = {
        expr = eval ''
          cabal-version: 3.0
          name: test-package
          version: 0.1

          library
            exposed-modules: Test.Types

          executable foo-exec
            main-is: foo.hs

          library extra-lib
            exposed-modules: Extra.Types

          test-suite unit-tests
            type: exitcode-stdio-1.0
            main-is: test.hs

          executable bar-exec
            main-is: bar.hs

          test-suite integration-tests
            type: exitcode-stdio-1.0
            main-is: integration.hs
        '';
        expected = {
          executable = [ "foo-exec" "bar-exec" ];
          library = [ "extra-lib" ];
          test-suite = [ "unit-tests" "integration-tests" ];
        };
      };
      testSingleStanza = {
        expr = eval ''
          cabal-version: 3.0
          name: test-package
          version: 0.1

          executable my-exe
            main-is: main.hs
        '';
        expected = {
          executable = [ "my-exe" ];
        };
      };
      testEmptyResults = {
        expr = eval ''
          cabal-version: 3.0
          name: test-package
          version: 0.1

          library
            exposed-modules: Test.Types
        '';
        expected = { };
      };
    };
  # Like lib.runTests, but actually fails if any test fails.
  runTestsFailing = tests:
    let
      res = lib.runTests tests;
    in
    if res == builtins.trace "All tests passed" [ ]
    then res
    else builtins.throw "Some tests failed: ${builtins.toJSON res}" res;
in
{
  "cabal.project" = runTestsFailing cabalProjectTests;
  "foo-bar.cabal" = runTestsFailing cabalExecutableTests;
  "cabal-stanzas" = runTestsFailing cabalStanzasTests;
}
