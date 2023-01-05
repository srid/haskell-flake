{
  description = "A `flake-parts` module for Haskell development";
  outputs = { self, ... }: {
    flakeModule = ./flake-module.nix;
    herculesCI.ciSystems = [ "x86_64-linux" "aarch64-darwin" ];
  };
}
