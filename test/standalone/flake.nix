{
  # Test: use haskell-flake without flake-parts, via the standalone lib API.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/870493f9a8cb0b074ae5b411b2f232015db19a65";
    haskell-flake = { };
  };
  outputs = { self, nixpkgs, haskell-flake, ... }:
    let
      eachSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      perSystem = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          project = (haskell-flake.lib { inherit pkgs; }).evalHaskellProject {
            projectRoot = self;
          };
        in
        {
          packages.default = project.packages.haskell-flake-test.package;
          devShells.default = project.devShell;
          checks.test = pkgs.runCommandNoCC "standalone-test" { } ''
            ${project.packages.haskell-flake-test.package}/bin/haskell-flake-test \
              | grep "Hello from standalone"
            touch $out
          '';
        };

      systemOutputs = eachSystem perSystem;
    in
    {
      packages = nixpkgs.lib.mapAttrs (_: s: s.packages) systemOutputs;
      devShells = nixpkgs.lib.mapAttrs (_: s: s.devShells) systemOutputs;
      checks = nixpkgs.lib.mapAttrs (_: s: s.checks) systemOutputs;
    };
}
