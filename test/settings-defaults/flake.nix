{
  # Since there is no flake.lock file (to avoid incongruent haskell-flake
  # pinning), we must specify revisions for *all* inputs to ensure
  # reproducibility.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/870493f9a8cb0b074ae5b411b2f232015db19a65";
    flake-parts.url = "github:hercules-ci/flake-parts/758cf7296bee11f1706a574c77d072b8a7baa881";
    haskell-flake = { };
    haskell-template.url = "github:srid/haskell-template/554b7c565396cf2d49a248e7e1dc0e0b46883b10";
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.haskell-flake.flakeModule
      ];
      debug = true;
      perSystem = { config, self', pkgs, lib, ... }: {
        haskellProjects.default = { };
        haskellProjectTests =
          let
            finalPackagesOf = projectName: config.haskellProjects.${projectName}.outputs.finalPackages;
            isSettingApplied = pkg: lib.hasAttr "setting-applied" pkg.meta;
          in
          {
            test-default-current = { name, ... }: {
              patches = [ ];
              extraHaskellProjectConfig = {
                imports = [
                  inputs.haskell-template.haskellFlakeProjectModules.output
                ];
                defaults.settings.local = {
                  custom = pkg: pkg.overrideAttrs (oldAttrs: {
                    meta = oldAttrs.meta // {
                      setting-applied = true;
                    };
                  });
                };
              };
              expect =
                lib.assertMsg
                  (lib.all (x: x) [
                    (! isSettingApplied (finalPackagesOf name).random)
                    (! isSettingApplied (finalPackagesOf name).haskell-template)
                    (isSettingApplied (finalPackagesOf name).haskell-flake-test)
                  ])
                  "defaults.settings: ${name} failed";
            };
            test-default-defined = { name, ... }: {
              patches = [ ];
              extraHaskellProjectConfig = {
                imports = [
                  inputs.haskell-template.haskellFlakeProjectModules.output
                ];
                defaults.settings.defined = {
                  custom = pkg: pkg.overrideAttrs (oldAttrs: {
                    meta = oldAttrs.meta // {
                      setting-applied = true;
                    };
                  });
                };
              };
              expect =
                lib.assertMsg
                  (lib.all (x: x) [
                    (! isSettingApplied (finalPackagesOf name).random)
                    (isSettingApplied (finalPackagesOf name).haskell-template)
                    (isSettingApplied (finalPackagesOf name).haskell-flake-test)
                  ])
                  "defaults.settings: ${name} failed";
            };
            test-default-all = { name, ... }: {
              patches = [ ];
              extraHaskellProjectConfig = {
                imports = [
                  inputs.haskell-template.haskellFlakeProjectModules.output
                ];
                settings.random = { };
                defaults.settings.all = {
                  custom = pkg: pkg.overrideAttrs (oldAttrs: {
                    meta = oldAttrs.meta // {
                      setting-applied = true;
                    };
                  });
                };
              };
              expect =
                lib.assertMsg
                  (lib.all (x: x) [
                    (isSettingApplied (finalPackagesOf name).random)
                    (isSettingApplied (finalPackagesOf name).haskell-template)
                    (isSettingApplied (finalPackagesOf name).haskell-flake-test)
                  ])
                  "defaults.settings: ${name} failed";
            };
          };
      };
    };
}
