project@{ name, pkgs, lib, ... }:

let
  inherit (lib)
    types;
  traceSettings = k: x:
    # Since attrs values are modules, we log only the keys.
    project.config.log.traceDebug "${k} ${builtins.toJSON (lib.attrNames x)}" x;
in
{
  options.settings = lib.mkOption {
    type = types.lazyAttrsOf types.deferredModule;
    default = { };
    description = ''
      Overrides for packages in `basePackages` and `packages`.

      Attr values are submodules that take the following arguments:

      - `name`: Package name
      - `self`/`super`: The 'self' and 'super' (aka. 'final' and 'prev') used in the Haskell overlay.
      - `pkgs`: Nixpkgs instance of the module user (import'er).
    '';
  };

  options.settingsOverlay = lib.mkOption {
    type = import ../../../types/haskell-overlay-type.nix { inherit lib; };
    description = ''
      The Haskell overlay computed from `settings` modules.
    '';
    internal = true;
    default = self: super:
      let
        applySettingsFor = name: mod:
          let
            cfg = (lib.evalModules {
              modules = [ ./all.nix mod ];
              specialArgs = {
                inherit name pkgs self super;
              } // (import ./lib.nix {
                inherit lib;
                # NOTE: Recursively referring generated config in lib.nix.
                config = cfg;
              });
            }).config;
          in
          lib.pipe super.${name} (
            # TODO: Do we care about the *order* of overrides?
            # Might be relevant for the 'custom' option.
            lib.concatMap
              (impl: impl)
              (lib.attrValues cfg.impl)
          );
      in
      traceSettings "${name}.settings.keys"
        (lib.mapAttrs applySettingsFor project.config.settings);
  };
}
