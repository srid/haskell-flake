project@{ name, pkgs, lib, ... }:

let
  inherit (lib)
    types;
  traceSettings = hpkg: x:
    let
      # Convert the settings config (x) to be stripped of functions, so we can
      # convert it to JSON for logging.
      xSanitized = lib.filterAttrs (s: v: 
        !(builtins.isFunction v) && !(s == "impl") && v != null) x;
    in
    project.config.log.traceDebug "settings.${hpkg} ${builtins.toJSON xSanitized}" x;
in
{
  options.settings = lib.mkOption {
    type = types.lazyAttrsOf types.deferredModule;
    default = { };
    apply = settings:
      # Polyfill local packages; because overlay's defaults setting merge requires it.
      let
        localPackages = 
          lib.pipe project.config.packages [
            (lib.filterAttrs (name: p: p.local))
            (lib.mapAttrs (_: _: {}))
          ];
        in localPackages // settings;
    description = ''
      Overrides for packages in `basePackages` and `packages`.

      Attr values are submodules that take the following arguments:

      - `name`: Package name
      - `package`: The reference to the package in `packages` option if it exists, null otherwise.
      - `self`/`super`: The 'self' and 'super' (aka. 'final' and 'prev') used in the Haskell overlay.
      - `pkgs`: Nixpkgs instance of the module user (import'er).

      Default settings are defined in `project.config.defaults.settings` which can be overriden.
    '';
  };

  options.settingsOverlay = lib.mkOption {
    type = import ../../../types/haskell-overlay-type.nix { inherit lib; };
    description = ''
      The Haskell overlay computed from `settings` modules, as well as
      `defaults.settings.default` module.
    '';
    internal = true;
    default = self: super:
      let
        applySettingsFor = name: mod:
          let
            cfg = (lib.evalModules {
              modules = [
                # Settings spec
                ./all.nix

                # Default settings
                project.config.defaults.settings.default

                # User module
                mod
              ];
              specialArgs = {
                inherit name pkgs self super;
                package = project.config.packages.${name} or null;
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
              (lib.attrValues (traceSettings name cfg).impl)
          );
      in
        lib.mapAttrs applySettingsFor project.config.settings;
  };
}
