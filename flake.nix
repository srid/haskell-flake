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
      path = builtins.path { path = ./example; filter = path: _: baseNameOf path != "test.sh"; };
    };

    # CI spec
    # https://github.com/srid/nixci
    nixci.default = {
      dev = {
        dir = "dev";
        overrideInputs."haskell-flake" = ./.;
      };

      doc = {
        dir = "doc";
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
          "haskell-flake" = ./.;
          "flake-parts" = "github:hercules-ci/flake-parts/7c7a8bce3dffe71203dcd4276504d1cb49dfe05f";
          "nixpkgs" = "github:nixos/nixpkgs/bb31220cca6d044baa6dc2715b07497a2a7c4bc7";
        };
      };

      # Legacy shell script test
      test = {
        dir = "test";
        overrideInputs."haskell-flake" = ./.;
        # Can't build on Linux until https://github.com/srid/haskell-flake/issues/241
        # TODO: Do the above, and get rid of this test.
        systems = [ "aarch64-darwin" "x86_64-darwin" ];
      };
    };
  };
}
