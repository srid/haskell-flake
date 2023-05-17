{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo listOf;
  mkImplOption = name: f: mkOption {
    # self: super: -> [ pkg -> pkg ]
    type = functionTo (functionTo (listOf (functionTo types.package)));
    description = ''
      Implementation for settings.${name}
    '';
    default = self: super:
      let
        cfg = config.${name};
      in
      lib.optional (cfg != null)
        (lib.pipe cfg [
          (applySelfSuper self super)
          f
        ]);
  };

  # Wrap a type such that we can pass *optional* 'self' and 'super' arguments.
  # This is poor man's module system, which we cannot use for whatever reason.
  mkSelfSuperOption = attrs:
    let
      withSelfSuper = t:
        types.either t (types.functionTo (types.functionTo t));
      selfSuperDescription = ''

    Optionally accepts arguments 'self' and 'super' reflecting the Haskell
    overlay arguments.
  '';
    in
    mkOption (attrs // {
      type = types.nullOr (withSelfSuper attrs.type);
      description = attrs.description + selfSuperDescription;
      default = null;
    });
  applySelfSuper = self: super: f:
    if builtins.isFunction f then f self super else f;

  # This creates `options.${name}` and `options.impl.${name}`.
  #
  # The user sets the former, whereas the latter provides the list of functions
  # to apply on the package (as implementation for this setting).
  mkCabalSettingOptions = { name, type, description, impl }: {
    "${name}" = mkSelfSuperOption {
      inherit type description;
    };
    impl."${name}" = mkImplOption name impl;
  };
in
{
  inherit mkCabalSettingOptions;
}
