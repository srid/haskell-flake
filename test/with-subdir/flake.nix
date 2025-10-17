{
  # Since there is no flake.lock file (to avoid incongruent haskell-flake
  # pinning), we must specify revisions for *all* inputs to ensure
  # reproducibility.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/870493f9a8cb0b074ae5b411b2f232015db19a65";
    flake-parts.url = "github:hercules-ci/flake-parts/758cf7296bee11f1706a574c77d072b8a7baa881";
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
        haskellProjects.default = { };

        # Test the default project by patching and evaluating the result.
        haskellProjectTests =
          let
            pkgOf = projectName: config.haskellProjects.${projectName}.outputs.finalPackages.haskell-flake-test;
            drvHash = drv: drv.drvPath;
            deriverHash = drv: drv.cabal2nixDeriver.drvPath;
          in
          {
            # Eval is constant under changes to irrelevant files
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
                  "touch-cabal-project failed";
            };

            # A relevant change to Haskell source causes a .drv change (control check)
            # But no cabal2nix re-eval
            touch-src = { name, ... }: {
              patches = [
                ''
                  diff --git a/haskell-flake-test/src/Main.hs b/haskell-flake-test/src/Main.hs
                  index fa10095..293744c 100644
                  --- a/haskell-flake-test/src/Main.hs
                  +++ b/haskell-flake-test/src/Main.hs
                  @@ -3,3 +3,5 @@ module Main where
                   main :: IO ()
                   main = do 
                     putStrLn "Hello"
                  +-- irrelevant comment
                  +

                ''
              ];
              expect =
                lib.assertMsg
                  (lib.all (x: x) [
                    (drvHash (pkgOf "default") != drvHash (pkgOf name))
                    (deriverHash (pkgOf "default") == deriverHash (pkgOf name))
                  ])
                  "touch-src failed";
            };

            # A relevant change to .cabal file causes cabal2nix re-eval
            touch-cabal = { name, ... }: {
              patches = [
                ''
                  diff --git a/haskell-flake-test/haskell-flake-test.cabal b/haskell-flake-test/haskell-flake-test.cabal
                  index 950a0ff..ef3131b 100644
                  --- a/haskell-flake-test/haskell-flake-test.cabal
                  +++ b/haskell-flake-test/haskell-flake-test.cabal
                  @@ -16,3 +16,5 @@ executable haskell-flake-test
                           base
                       hs-source-dirs:   src
                       default-language: Haskell2010
                  +-- irrelevant comment
                  +
                ''
              ];
              expect =
                lib.assertMsg
                  (lib.all (x: x) [
                    (drvHash (pkgOf "default") != drvHash (pkgOf name))
                    (deriverHash (pkgOf "default") != deriverHash (pkgOf name))
                  ])
                  "touch-src failed";
            };
          };
      };
    };
}
