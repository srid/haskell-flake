{ pkgs, lib, ... }:

let
  inherit (lib)
    types;
  settingsSubmodule = {
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
    options.impl = lib.mkOption {
      type = types.submodule { };
      internal = true;
      visible = false;
      default = { };
      description = ''
        Implementation for options in 'settings'
      '';
    };
  };
in
{
  options.settings = lib.mkOption {
    type = types.lazyAttrsOf types.deferredModule;
    default = { };
    apply = settings:
      lib.mapAttrs
        (k: v:
          (lib.evalModules {
            modules = [ settingsSubmodule v ];
            specialArgs = { inherit pkgs lib; } // (import ./lib.nix {
              inherit lib;
            });
          }).config
        )
        settings;
    description = ''
      Overrides for packages in `basePackages` and `packages`.
    '';
  };
}
