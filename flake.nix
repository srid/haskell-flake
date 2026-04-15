{
  description = "Nix library for Haskell development (standalone or as a flake-parts module)";
  nixConfig = {
    extra-substituters = "https://cache.nixos.asia/oss";
    extra-trusted-public-keys = "oss:KO872wNJkCDgmGN3xy9dT89WAhvv13EiKncTtHDItVU=";
  };
  outputs = inputs: {
    flakeModule = ./nix/modules;
    lib = import ./nix/lib.nix;

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
