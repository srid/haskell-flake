{
  # Since there is no flake.lock file (to avoid incongruent haskell-flake
  # pinning), we must specify revisions for *all* inputs to ensure
  # reproducibility.
  inputs = {
    nixpkgs = { };
    flake-parts = { };
    haskell-flake = { };
    haskell-template = { };
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
