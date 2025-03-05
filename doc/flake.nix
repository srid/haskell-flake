{
  nixConfig = {
    extra-substituters = "https://srid.cachix.org";
    extra-trusted-public-keys = "srid.cachix.org-1:3clnql5gjbJNEvhA/WQp7nrZlBptwpXnUk6JAv8aB2M=";
  };

  inputs = {
    cfp.url = "github:flake-parts/community.flake.parts";
    nixpkgs.follows = "cfp/nixpkgs";
    flake-parts.follows = "cfp/flake-parts";

    # flake-parts-website.url = "github:hercules-ci/flake.parts-website";
    # flake-parts-website.inputs.haskell-flake.follows = "haskell-flake";
    # flake-parts-website.inputs.flake-parts.follows = "flake-parts";

    haskell-flake.url = "github:srid/haskell-flake";
  };

  outputs = inputs@{ self, flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.cfp.flakeModules.default
      ];
      perSystem = { self', inputs', pkgs, system, ... }: {
        flake-parts-docs = {
          enable = true;
          modules."haskell-flake" = {
            path = self;
            pathString = ".";
          };
        };
        formatter = pkgs.nixpkgs-fmt;

        # Disable linkcheck due to upstream issue
        # https://github.com/hercules-ci/flake.parts-website/issues/1367
        /*
        checks.linkcheck = inputs'.flake-parts-website.checks.linkcheck;
        packages.flake-parts = inputs'.flake-parts-website.packages.default;
        apps.flake-parts.program = pkgs.writeShellApplication {
          name = "docs-flake-parts";
          meta.description = "Open flake.parts docs, previewing local haskell-flake version";
          text = ''
            DOCSHTML="${self'.packages.flake-parts}/options/haskell-flake.html"

            if [ "$(uname)" == "Darwin" ]; then
              open $DOCSHTML
            else 
              if type xdg-open &>/dev/null; then
                xdg-open $DOCSHTML
              fi
            fi
          '';
        };
        */
      };
    };
}
