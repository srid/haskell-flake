{
  # Test case for verifying that settings.x.custom can handle multiple functions
  # from different modules (like defaults and user settings) without conflicts.
  inputs = {
    nixpkgs = { };
    flake-parts = { };
    haskell-flake = { };
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.haskell-flake.flakeModule
      ];
      debug = true;
      perSystem = { config, self', pkgs, lib, ... }: {
        haskellProjects.default = {
          # Test defaults.settings.all can set custom functions
          defaults.settings.all = {
            custom = [ (pkg: pkg.overrideAttrs (old: {
              meta = old.meta // { defaultsApplied = true; };
            })) ];
          };
          
          # Test that user settings can add additional custom functions
          settings = {
            custom-merge-test = {
              custom = [ 
                (pkg: pkg.overrideAttrs (old: {
                  meta = old.meta // { userCustom1 = true; };
                }))
                (pkg: pkg.overrideAttrs (old: {
                  meta = old.meta // { userCustom2 = true; };
                }))
              ];
            };
          };
          
          packages = {
            custom-merge-test.source = pkgs.writeTextDir "custom-merge-test.cabal" ''
              cabal-version: 2.4
              name: custom-merge-test
              version: 0.1.0.0
              library
                exposed-modules: Lib
                build-depends: base
                hs-source-dirs: src
            '' + pkgs.writeTextDir "src/Lib.hs" ''
              module Lib where
              x = "test"
            '';
          };
        };
        
        # Test that verifies the multiple custom functions are applied
        checks.test-custom-merge = 
          let
            pkg = config.haskellProjects.default.outputs.finalPackages.custom-merge-test;
          in
          pkgs.runCommand "test-custom-merge" {} ''
            # Check that all custom functions were applied
            ${lib.optionalString (!(pkg.meta.defaultsApplied or false))
              "echo 'ERROR: defaults.settings.all custom function was not applied'; exit 1"}
            ${lib.optionalString (!(pkg.meta.userCustom1 or false))
              "echo 'ERROR: user custom function 1 was not applied'; exit 1"}
            ${lib.optionalString (!(pkg.meta.userCustom2 or false))
              "echo 'ERROR: user custom function 2 was not applied'; exit 1"}
            
            echo "SUCCESS: All custom functions were applied correctly"
            echo "defaultsApplied: ${builtins.toString (pkg.meta.defaultsApplied or false)}" 
            echo "userCustom1: ${builtins.toString (pkg.meta.userCustom1 or false)}"
            echo "userCustom2: ${builtins.toString (pkg.meta.userCustom2 or false)}"
            touch $out
          '';
      };
    };
}