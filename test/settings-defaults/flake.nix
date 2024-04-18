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
            isSettingApplied = pkg: pkg.meta.setting-applied == true;
            isSettingUnApplied = pkg: (lib.hasAttr "setting-applied" pkg.meta) == false;
          in
          {
            test-default-current = { name, ... }: {
              patches = [ ];
              extraHaskellProjectConfig = {
                imports = [
                  inputs.haskell-template.haskellFlakeProjectModules.output
                ];
                defaults.settings.default-current = {
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
                    (isSettingUnApplied (finalPackagesOf name).hello)
                    (isSettingUnApplied (finalPackagesOf name).haskell-template)
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
                defaults.settings.default-defined = {
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
                    (isSettingUnApplied (finalPackagesOf name).hello)
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
                settings.hello = { };
                defaults.settings.default-all = {
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
                    (isSettingApplied (finalPackagesOf name).hello)
                    (isSettingApplied (finalPackagesOf name).haskell-template)
                    (isSettingApplied (finalPackagesOf name).haskell-flake-test)
                  ])
                  "defaults.settings: ${name} failed";
            };
          };
      };
    };
}
