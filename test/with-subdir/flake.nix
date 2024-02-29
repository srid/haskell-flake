{
  # Since there is no flake.lock file (to avoid incongruent haskell-flake
  # pinning), we must specify revisions for *all* inputs to ensure
  # reproducibility.
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
        ./haskell-flake-patch.nix
      ];
      debug = true;
      perSystem = { config, self', pkgs, lib, ... }: {
        haskellProjects.default = { };

        # Test the default project by patching and evaluating the result.
        haskellProjectTests =
          let
            pkgOf = projectName: config.haskellProjects.${projectName}.outputs.finalPackages.haskell-flake-test;
            drvHash = drv: drv.drvPath;
            deriverHash = drv: drv.cabal2nixDeriver.drvPath;
          in
          {
            # Make an innocent change to cabal.project 
            # ➡️ The derivation must not be rebuilt.
            touch-cabal-project = { name, ... }: {
              patches = [
                ''
                  diff --git a/cabal.project b/cabal.project
                  index 1a862c3..92dd52b 100644
                  --- a/cabal.project
                  +++ b/cabal.project
                  @@ -1,2 +1,4 @@
                    packages:
                  -  ./haskell-flake-test
                  \ No newline at end of file
                  +  ./haskell-flake-test
                  +-- irrelevant comment
                  +
                ''
              ];
              expect =
                lib.assertMsg
                  (lib.all (x: x) [
                    (drvHash (pkgOf "default") == drvHash (pkgOf name))
                    (deriverHash (pkgOf "default") == deriverHash (pkgOf name))
                  ])
                  "they must be equal";
            };
          };
      };
    };
}
