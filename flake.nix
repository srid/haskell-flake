{
  description = "A `flake-parts` module for Haskell development";
  outputs = { ... }: {
    flakeModule = ./nix/modules;

    templates.default = {
      description = "A simple flake.nix using haskell-flake";
      path = builtins.path { path = ./example; filter = path: _: baseNameOf path == "flake.nix"; };
    };
    templates.example = {
      description = "Example Haskell project using haskell-flake";
      path = builtins.path { path = ./example; };
    };

    # CI spec
    # https://github.com/srid/nixci
    nixci.default =
      let
        exampleLock = builtins.fromJSON (builtins.readFile ./example/flake.lock);
        nixpkgs = "github:nixos/nixpkgs/" + exampleLock.nodes.nixpkgs.locked.rev;
        flake-parts = "github:hercules-ci/flake-parts/" + exampleLock.nodes.flake-parts.locked.rev;
      in
      {
        dev = {
          dir = "dev";
          overrideInputs."haskell-flake" = ./.;
        };

        doc = {
          dir = "doc";
          overrideInputs = {
            "haskell-flake" = ./.;
            "flake-parts-website" = "github:hercules-ci/flake.parts-website";
          };
        };

        example = {
          dir = "example";
          overrideInputs."haskell-flake" = ./.;
        };

        # Tests
        haskell-parsers-test = {
          dir = ./nix/haskell-parsers/test;
          overrideInputs."haskell-parsers" = ./nix/haskell-parsers;
        };

        test-simple = {
          dir = "test/simple";
          overrideInputs = {
            inherit nixpkgs flake-parts;
            "haskell-flake" = ./.;
          };
        };

        test-project-module = {
          dir = "test/project-module";
          overrideInputs = {
            inherit nixpkgs flake-parts;
            "haskell-flake" = ./.;
          };
        };

        # Legacy shell script test
        legacy-test = {
          dir = "test";
          overrideInputs."haskell-flake" = ./.;
          # Can't build on Linux until https://github.com/srid/haskell-flake/issues/241
          # TODO: Do the above, and get rid of this test.
          systems = [ "aarch64-darwin" "x86_64-darwin" ];
        };
      };
  };
}
