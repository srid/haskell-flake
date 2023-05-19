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

  # This submodule will be populated as `options.impl.${name}` for each of the
  # imports above. The implementation for this is in lib.nix.
  options.impl = mkOption {
    type = types.submodule { };
    internal = true;
    visible = false;
    default = { };
    description = ''
      Implementation for options in 'settings'
    '';
  };
}
