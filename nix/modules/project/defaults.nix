# A module representing the default values used internally by haskell-flake.
{ lib, ... }:
let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo;
in
{
  options.defaults = {
    devShell.tools = mkOption {
      type = functionTo (types.attrsOf (types.nullOr types.package));
      description = ''Build tools always included in devShell'';
      default = hp: with hp; {
        inherit
          cabal-install
          haskell-language-server
          ghcid
          hlint;
      };
    };
  };
}
