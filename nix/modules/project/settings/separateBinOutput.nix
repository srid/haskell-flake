{ config, pkgs, lib, mkCabalSettingOptions, ... }:

let
  inherit (lib)
    types;
in
{
  options = mkCabalSettingOptions {
    inherit config;
    name = "separateBinOutput";
    type = types.bool;
    description = ''
      Create two outputs for this Haskell package -- 'out' and 'bin'. This is
      useful to separate out the binary with a reduced closure size.
    '';
    impl = enable: with pkgs.haskell.lib.compose;
      let
        disableSeparateBinOutput =
          overrideCabal (drv: { enableSeparateBinOutput = false; });
      in
      if enable then enableSeparateBinOutput else disableSeparateBinOutput;
  };
}
