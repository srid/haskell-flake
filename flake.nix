{
  description = "A `flake-parts` module for Haskell development";
  outputs = { self, ... }: {
    flakeModule = ./nix/flake-module.nix;
    templates.default = {
      description = "A simple flake.nix using haskell-flake";
      path = builtins.path { path = ./example; filter = path: _: baseNameOf path == "flake.nix"; };
    };
    templates.example = {
      description = "Example Haskell project using haskell-flake";
      path = ./example;
    };
  };
}
