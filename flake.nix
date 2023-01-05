{
  description = "A `flake-parts` module for Haskell development";
  inputs = {
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
  };
  outputs = { self, nixpkgs-lib, ... }: {
    flakeModule = ./flake-module.nix;
    templates.default.path = (nixpkgs-lib.lib.cleanSourceWith {
      src = ./example;
      filter = path: type: baseNameOf path == "flake.nix";
    }).outPath;
    herculesCI.ciSystems = [ "x86_64-linux" "aarch64-darwin" ];
  };
}
