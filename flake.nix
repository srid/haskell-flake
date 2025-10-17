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
        template = inputs.self.templates.example;
        params = [
          {
            name = "package-name";
            description = "Name of the Haskell package";
            placeholder = "example";
          }
        ];
      };
    };
  };
}
