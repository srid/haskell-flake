# Provides the `mkCabalSettingOptions` helper for defining settings.<name>.???.
{ lib, config, ... }:

let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo listOf nullOr;

  # Default is 1000
  # https://github.com/hsjobeki/nixpkgs/blob/e0c7b345cdd986ccdbde3744ff8a0740596de834/lib/modules.nix#L1166
  settingPriorities = {
    # buildFromSdist must apply *after* other settings, else it breaks
    # cf. https://github.com/srid/haskell-flake/pull/252
    buildFromSdist = 1700;

    # Apply 'custom' last (but before buildFromSdist; see above), to give
    # the user maximum control.
    custom = 1600;
  };

  mkImplOption = name: f: mkOption {
    # [ pkg -> pkg ]
    type = listOf (functionTo types.package);
    description = ''
      Implementation for settings.${name}
    '';
    default =
      let
        cfg = config.${name};
        fns =
          if cfg != null then
            (
              let g = f cfg;
              in lib.optional (g != null) g
            ) else [ ];
      in
      # if lib.hasAttr name settingPriorities then
      lib.mkOrder (settingPriorities.${name} or 1000) fns;
    # else fns;
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
