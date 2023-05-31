{ lib, ... }:

let
  isPathUnderNixStore = path: builtins.hasContext (builtins.toString path);
in
lib.mkOptionType {
  name = "haskell-source";
  description = ''
    Path to Haskell package source, or version from Hackage.
  '';
  descriptionClass = "noun";
  check = path:
    isPathUnderNixStore path || builtins.isString path;
  merge = lib.mergeOneOption;
}
