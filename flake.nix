{
  description = "A `flake-parts` module for Haskell development";
  outputs = inputs: {
    flakeModule = ./nix/modules;

    templates.default = {
      description = "A simple flake.nix using haskell-flake";
      path = builtins.path { path = ./example; filter = path: _: baseNameOf path == "flake.nix"; };
    };
    templates.example = {
      description = "Example Haskell project using haskell-flake";
      path = builtins.path { path = ./example; };
    };

    nixci-matrix =
      let
        subFlakes = builtins.attrNames inputs.self.nixci.default;
        include =
          builtins.concatMap
            (system:
              builtins.map
                (subflake: {
                  inherit system subflake;
                  config = "default";
                })
                subFlakes
            ) [ "aarch64-linux" "aarch64-darwin" ];
      in
      {
        inherit include;
      };

    # CI spec
    # https://github.com/srid/nixci
    nixci.default =
      let
        exampleLock = builtins.fromJSON (builtins.readFile ./example/flake.lock);
        nixpkgs = "github:nixos/nixpkgs/" + exampleLock.nodes.nixpkgs.locked.rev;
        flake-parts = "github:hercules-ci/flake-parts/" + exampleLock.nodes.flake-parts.locked.rev;
        haskell-flake = ./.;
        haskell-parsers = ./nix/haskell-parsers;
      in
      {
        dev = {
          dir = "dev";
          overrideInputs = { inherit haskell-flake; };
        };

        doc = {
          dir = "doc";
          overrideInputs = { inherit haskell-flake; };
        };

        example = {
          dir = "example";
          overrideInputs = { inherit haskell-flake; };
        };

        # Tests
        haskell-parsers-test = {
          dir = ./nix/haskell-parsers/test;
          overrideInputs = { inherit haskell-parsers; };
        };

        test-simple = {
          dir = "test/simple";
          overrideInputs = {
            inherit nixpkgs flake-parts haskell-flake;
          };
        };

        test-with-subdir = {
          dir = "test/with-subdir";
          overrideInputs = {
            inherit nixpkgs flake-parts haskell-flake;
          };
        };

        test-project-module = {
          dir = "test/project-module";
          overrideInputs = {
            inherit nixpkgs flake-parts haskell-flake;
          };
        };
      };
  };
}
