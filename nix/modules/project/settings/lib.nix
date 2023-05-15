# Provides the `mkCabalSettingOptions` helper for defining settings.<name>.???.
{ lib, ... }:

let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo listOf;

  mkImplOption = config: name: f: mkOption {
    # [ pkg -> pkg ]
    type = listOf (functionTo types.package);
    description = ''
      Implementation for settings.${name}
    '';
    default =
      let
        cfg = config.${name};
      in
      lib.optional (cfg != null)
        (f cfg);
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
  mkCabalSettingOptions = { config, name, type, description, impl }: {
    "${name}" = mkNullableOption {
      inherit type description;
    };
    impl."${name}" = mkImplOption config name impl;
  };
in
{
  inherit mkCabalSettingOptions;
}
