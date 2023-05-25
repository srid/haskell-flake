project@{ name, pkgs, lib, ... }:

let
  inherit (lib)
    types;
  settingsSubmodule = {
    imports = [
      ./check.nix
      ./jailbreak.nix
      ./broken.nix
      ./haddock.nix
      ./libraryProfiling.nix
      ./executableProfiling.nix
      ./extraBuildDepends.nix
      ./justStaticExecutables.nix
      ./separateBinOutput.nix
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

      Attr values are modules that take the following arguments:

      - name: The key of the attr value.
      - self/super: The 'self' and 'super' (aka. 'final' and 'prev') used in the Haskell overlauy.
      - pkgs: Nixpkgs instance of the module user (import'er).
    '';
  };

  options.evalSettings = lib.mkOption {
    type = types.functionTo types.raw;
    default = settings: self: super:
      traceSettings "${name}.settings:apply.keys"
        (lib.mapAttrs
          (k: v:
            self: super: (lib.evalModules {
              modules = [ settingsSubmodule v ];
              specialArgs = {
                inherit pkgs lib self super;
                name = k;
              }
              // (import ./lib.nix {
                inherit lib self super;
              });
            }).config
          )
          settings);
  };
}
