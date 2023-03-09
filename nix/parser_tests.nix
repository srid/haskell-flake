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
in
{
  "cabal.project" = lib.runTests cabalProjectTests;
  "package.yaml" = lib.runTests packageYamlTests;
}
