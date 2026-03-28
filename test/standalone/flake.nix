{
  # Test: use haskell-flake without flake-parts, via the standalone lib API.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/870493f9a8cb0b074ae5b411b2f232015db19a65";
    haskell-flake = { };
  };
  outputs = { self, nixpkgs, haskell-flake, ... }:
    let
      eachSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      packages = eachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          project = (haskell-flake.lib { inherit pkgs; }).evalHaskellProject {
            projectRoot = self;
          };
        in
        {
          default = project.packages.haskell-flake-test.package;
        });

      devShells = eachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          project = (haskell-flake.lib { inherit pkgs; }).evalHaskellProject {
            projectRoot = self;
          };
        in
        {
          default = project.devShell;
        });

      checks = eachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          project = (haskell-flake.lib { inherit pkgs; }).evalHaskellProject {
            projectRoot = self;
          };
        in
        {
          test = pkgs.runCommandNoCC "standalone-test"
            { }
            ''
              ${project.packages.haskell-flake-test.package}/bin/haskell-flake-test \
                | grep "Hello from standalone"
              touch $out
            '';
        });
    };
}
