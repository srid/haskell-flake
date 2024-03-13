{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [ inputs.haskell-flake.flakeModule ];

      perSystem = { config, self', pkgs, lib, ... }: {
        haskellProjects.default = { };

        haskellProjectTests =
          let
            pkgOf = projectName: config.haskellProjects.${projectName}.outputs.finalPackages.example;
            drvHash = drv: drv.drvPath;
            deriverHash = drv: drv.cabal2nixDeriver.drvPath;
          in
          {
            # Changing a top-level file should not rebuild the top-level package.
            touch-top = { name, ... }: {
              patches = [
                ''
                  diff --git a/flake.nix b/flake.nix
                  index aeddc5e..6a5274e 100644
                  --- a/flake.nix
                  +++ b/flake.nix
                  @@ -1,3 +1,4 @@
                  +# Touch
                   {
                     inputs = {
                       nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
                ''
              ];
              expect =
                lib.assertMsg
                  (lib.all (x: x) [
                    # FIXME: These should be equivalent
                    (drvHash (pkgOf "default") != drvHash (pkgOf name))
                    (deriverHash (pkgOf "default") == deriverHash (pkgOf name))
                  ])
                  "touch-top failed";
            };
          };
      };
    };
}
