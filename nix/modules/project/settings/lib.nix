# Provides the `mkCabalSettingOptions` helper for defining settings.<name>.???.
{ lib, config, ... }:

let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo listOf nullOr;

  mkImplOption = name: f: mkOption {
    # [ pkg -> pkg ]
    type = listOf (nullOr (functionTo types.package));
    description = ''
      Implementation for settings.${name}
    '';
    default =
      let
        cfg = config.${name};
      in
      if cfg != null then
        (
          let g = f cfg;
          in lib.optional (g != null) g
        ) else [ ];
  };


  mkNullableOption = attrs:
    mkOption (attrs // {
      type = types.nullOr attrs.type;
      default = null;
    });

  # This creates `options.${name}` and `options.impl.${name}`.
  #
  # The user sets the former, whereas the latter provides the list of functions
  # to apply on the package (as implementation for this setting).
  mkCabalSettingOptions = { name, type, description, impl }: {
    "${name}" = mkNullableOption {
      inherit type description;
    };
    impl."${name}" = mkImplOption name impl;
  };
in
{
  inherit mkCabalSettingOptions;
}
