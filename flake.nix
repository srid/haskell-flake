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

    # https://github.com/srid/nixci
    nixci.default =
      let
        overrideInputs = { "haskell-flake" = ./.; };
      in
      {
        dev = { inherit overrideInputs; dir = "dev"; };
        doc = { dir = "doc"; };
        example = { inherit overrideInputs; dir = "example"; };

        # Tests
        haskell-parsers-test = {
          overrideInputs."haskell-parsers" = ./nix/haskell-parsers;
          dir = ./nix/haskell-parsers/test;
        };
        # Legacy shell script test
        # TODO: Port to pure Nix; see https://github.com/srid/haskell-flake/issues/241
        test = { inherit overrideInputs; dir = "test"; };
      };
  };
}
