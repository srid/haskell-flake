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
in
lib.runTests cabalProjectTests
