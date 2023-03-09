{
  description = "A `flake-parts` module for Haskell development";
  inputs.nix-parsec.url = "github:kanwren/nix-parsec";
  outputs = { self, nix-parsec, ... }: {
    flakeModule = import ./nix/flake-module.nix { inherit nix-parsec; };
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
