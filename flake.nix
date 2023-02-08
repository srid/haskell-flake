{
  description = "A `flake-parts` module for Haskell development";
  outputs = { self, ... }: {
    flakeModule = ./flake-module.nix;
    templates.default = {
      description = "Example project using haskell-flake";
      path = ./example;
    };
    templates.flake-only = {
      description = "Example flake using haskell-flake";
      path = builtins.path {path=./example; filter = path: _: baseNameOf path == "flake.nix";};
    };
  };
}
