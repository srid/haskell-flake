{
  description = "A `flake-parts` module for Haskell development";
  outputs = { self, ... }: {
    flakeModule = ./flake-module.nix;
  };
}
