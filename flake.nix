{
  description = "A `flake-parts` module for Haskell development";
  outputs = { self, ... }: {
    flakeModule = ./flake-module.nix;
    templates.default = {
      description = "Example project using haskell-flake";
      path = ./example;
    };
  };
}
