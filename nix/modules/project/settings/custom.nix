{ config, lib, mkCabalSettingOptions, ... }:

let
  inherit (lib)
    types;
in
{
  options = mkCabalSettingOptions {
    inherit config;
    name = "custom";
    type = types.functionTo types.package;
    description = ''
      A custom funtion to apply on the Haskell package.

      Use this only if none of the existing settings are suitable.

      The function must take three arguments: self, super and the package being
      applied to.

      Example:

          custom = pkg: builtins.trace pkg.version pkg;
    '';
    impl = f: f;
  };
}