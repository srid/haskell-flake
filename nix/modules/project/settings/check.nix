{ pkgs, lib, config, ... }:

let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo listOf;
  mkImplOption = name: default: mkOption {
    # self: super: -> [ pkg -> pkg ]
    type = functionTo (functionTo (listOf (functionTo types.package)));
    description = ''
      Implementation for settings.${name}
    '';
    inherit default;
  };
in
{
  options = with pkgs.haskell.lib.compose; {
    check = mkOption {
      type = types.nullOr types.bool;
      description = ''
        Whether to run cabal tests as part of the nix build
      '';
      default = null;
    };
    impl.check = mkImplOption "check" (_: _:
      lib.optional (config.check != null)
        (if config.check then doCheck else dontCheck)
    );
  };
}
