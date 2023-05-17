{ lib, ... }:

let
  inherit (lib)
    mkOption
    types;
in
{
  imports = [
    ./check.nix
    ./haddock.nix
    ./libraryProfiling.nix
    ./executableProfiling.nix
    ./extraBuildDepends.nix
    ./justStaticExecutables.nix
    ./removeReferencesTo.nix
    ./custom.nix
  ];

  options.settings.impl = mkOption {
    type = types.submodule { };
    internal = true;
    readOnly = true;
    hidden = true;
    description = ''
      Implementation for options in 'settings'
    '';
  };
}
