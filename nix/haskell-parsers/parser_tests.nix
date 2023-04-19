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
    };
  packageYamlTests =
    let
      eval = s:
        let res = parser.parsePackageYamlName s; in
        if res.type == "success" then res.value else res;
    in
    {
      testSimple = {
        expr = eval ''
          name: foo
        '';
        expected = "foo";
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
  "package.yaml" = runTestsFailing packageYamlTests;
  "foo-bar.cabal" = runTestsFailing cabalExecutableTests;
}
