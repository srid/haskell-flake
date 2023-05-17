{ lib, ... }:

let
  inherit (lib)
    mkOption
    types;
in
{
  imports = [
    ./check.nix
    ./extraBuildDepends.nix
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
