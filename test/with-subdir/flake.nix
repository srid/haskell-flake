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
        haskellProjectTests = {
          # Make an innocent change to cabal.project 
          # ➡️ The derivation must not be rebuilt.
          touch-cabal-project =
            let
              getDrvPath = drv: drv.drvPath;
              getCabal2nixDeriverDrvpath = drv: drv.cabal2nixDeriver.drvPath;
              baseline = getDrvPath self'.packages.haskell-flake-test;
              baseline_cabal2nix = getCabal2nixDeriverDrvpath self'.packages.haskell-flake-test;
            in
            {
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
                  (baseline == getDrvPath config.haskellProjects.touch-cabal-project.outputs.finalPackages.haskell-flake-test
                    && baseline_cabal2nix == getCabal2nixDeriverDrvpath config.haskellProjects.touch-cabal-project.outputs.finalPackages.haskell-flake-test
                  )
                  "they must be equal";
            };
        };
      };
    };
}
