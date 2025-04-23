{
  # Since there is no flake.lock file (to avoid incongruent haskell-flake
  # pinning), we must specify revisions for *all* inputs to ensure
  # reproducibility.
  inputs = {
    nixpkgs = { };
    flake-parts = { };
    haskell-flake = { };

    haskell-multi-nix.url = "github:srid/haskell-multi-nix/7aed736571714ec12105ec110358998d70d59e34";
    haskell-multi-nix.flake = false;
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.haskell-flake.flakeModule
      ];
      flake.haskellFlakeProjectModules.default = { pkgs, lib, ... }: {
        packages = {
          # This is purposefully incorrect (pointing to ./.) because we
          # expect it to be overriden in perSystem below.
          foo.source = ./.;
        };
        settings = {
          # Test that self and super are passed
          foo = { self, super, ... }: {
            custom = _: builtins.seq
              (lib.assertMsg (lib.hasAttr "ghc" self) "self is bad")
              super.foo;
          };
        };
        devShell = {
          tools = hp: {
            # Setting to null should remove this tool from defaults.
            ghcid = null;
          };
        };
      };
      perSystem = { self', pkgs, lib, ... }: {
        haskellProjects.default = {
          # Multiple modules should be merged correctly.
          imports = [ self.haskellFlakeProjectModules.default ];
          packages = {
            # Because the module being imported above also defines a root for
            # the 'foo' package, we must override it here using `lib.mkForce`.
            foo.source = lib.mkForce (inputs.haskell-multi-nix + /foo);
          };
          settings = {
            foo = {
              jailbreak = true;
              cabalFlags.blah = true;
            };
            haskell-flake-test = {
              # Test STatic ANalysis report generation
              stan = true;
              # Test if user's setting overrides the `jailbreak = false;` override by `buildFromSdist`
              jailbreak = true;
            };
          };
          devShell = {
            tools = hp: {
              # Adding a tool should make it available in devshell.
              inherit (pkgs) fzf;
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

        # Our test
        checks.test =
          pkgs.runCommandNoCC "simple-test"
            {
              nativeBuildInputs = with pkgs; [
                which
              ] ++ self'.devShells.default.nativeBuildInputs;

              # Test defaults.settings module behaviour, viz: haddock
              NO_HADDOCK =
                lib.assertMsg (!lib.hasAttr "doc" self'.packages.default)
                  "doc output should not be present";
            }
            ''
              (
              set -x
              echo "Testing test/simple ..."

              # Run the cabal executable as flake app
              ${self'.apps.app1.program} | grep fooFunc

              # Setting buildTools.ghcid to null should disable that default
              # buildTool (ghcid)
              which ghcid && \
                (echo "ghcid should not be in devshell"; exit 2)

              # Adding a buildTool (fzf, here) should put it in devshell.
              which fzf || \
                (echo "fzf should be in devshell"; exit 2)

              # mkShellArgs works
              ${self'.devShells.default.shellHook}
              if [[ "$FOO" == "bar" ]]; then 
                  echo "$FOO"
              else 
                  echo "FOO is not bar" 
                  exit 2
              fi

              # extraLibraries works
              runghc ${./script} | grep -F 'TOML-flavored boolean: Bool True'

              touch $out
              )
            '';
      };
    };
}
