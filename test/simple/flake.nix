{
  # Since there is no flake.lock file (to avoid incongruent haskell-flake
  # pinning), we must specify revisions for *all* inputs to ensure
  # reproducibility.
  inputs = {
    nixpkgs = { };
    flake-parts = { };
    haskell-flake = { };

    check-flake.url = "github:srid/check-flake/48a17393ed4fcd523399d6602c283775b5127295";

    haskell-multi-nix.url = "github:srid/haskell-multi-nix/7aed736571714ec12105ec110358998d70d59e34";
    haskell-multi-nix.flake = false;
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.haskell-flake.flakeModule
        inputs.check-flake.flakeModule
      ];
      flake.haskellFlakeProjectModules.default = { pkgs, ... }: {
        overrides = self: super: {
          # This is purposefully incorrect (pointing to ./.) because we
          # expect it to be overriden in perSystem below.
          foo = self.callCabal2nix "foo" ./. { };
        };
        devShell = {
          tools = hp: {
            # Setting to null should remove this tool from defaults.
            ghcid = null;
          };
          hlsCheck.enable = true;
        };
      };
      perSystem = { self', pkgs, ... }: {
        haskellProjects.default = {
          # Multiple modules should be merged correctly.
          imports = [ self.haskellFlakeProjectModules.default ];
          overrides = self: super: {
            # This overrides the overlay above (in `flake.*`), because the
            # module system merges them in such order. cf. the WARNING in option
            # docs.
            foo = self.callCabal2nix "foo" (inputs.haskell-multi-nix + /foo) { };
          };
          devShell = {
            tools = hp: {
              # Adding a tool should make it available in devshell.
              fzf = pkgs.fzf;
            };
            extraLibraries = hp: {
              inherit (hp) tomland;
            };
            mkShellArgs.shellHook = ''
              echo "Hello from devshell!"
              export FOO=bar
            '';
          };
        };
        packages.default = self'.packages.haskell-flake-test;

        # An explicit app to test `nix run .#test` (*without* falling back to
        # using self.packages.test)
        apps.app1 = self'.apps.haskell-flake-test;
      };
    };
}
