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

    om = {
      # https://omnix.page/om/init.html#spec
      templates.haskell-flake = {
        template = inputs.templates.example;
        params = [
          {
            name = "package-name";
            description = "Name of the Haskell package";
            placeholder = "example";
          }
        ];
      };

      # CI spec
      # https://omnix.page/om/ci.html
      ci.default =
        let
          exampleLock = builtins.fromJSON (builtins.readFile ./example/flake.lock);
          nixpkgs = "github:nixos/nixpkgs/" + exampleLock.nodes.nixpkgs.locked.rev;
          flake-parts = "github:hercules-ci/flake-parts/" + exampleLock.nodes.flake-parts.locked.rev;
          haskell-flake = ./.;
          haskell-parsers = ./nix/haskell-parsers;
          haskell-template = "github:srid/haskell-template/554b7c565396cf2d49a248e7e1dc0e0b46883b10";
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
            dir = "./nix/haskell-parsers/test";
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
  
          test-settings-defaults = {
            dir = "test/settings-defaults";
            overrideInputs = {
              inherit nixpkgs flake-parts haskell-flake haskell-template;
            };
          };
  
          test-otherOverlays = {
            dir = "test/otherOverlays";
            overrideInputs = {
              inherit nixpkgs flake-parts haskell-flake;
            };
          };
        };
      };
  };
}
