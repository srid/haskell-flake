{
  # Since there is no flake.lock file (to avoid incongruent haskell-flake
  # pinning), we must specify revisions for *all* inputs to ensure
  # reproducibility.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/bb31220cca6d044baa6dc2715b07497a2a7c4bc7";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # We do not specify a value for this input, because it is explicitly
    # specified using --override-input to point to ../. For example, 
    #   `nix build --override-input haskell-flake ..`
    haskell-flake = { };
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [ inputs.haskell-flake.flakeModule ];
      perSystem = { self', pkgs, ... }: {
        haskellProjects.default = {
          packages = {
            # You can add more than one local package here.
            haskell-flake-test.root = ./.; # Assumes ./haskell-flake-test.cabal
          };
          buildTools = hp: {
            # Some buildTools are included by default. If you do not want them,
            # set them to 'null' here.
            ghcid = null;
            # You can also add additional build tools.
            fzf = pkgs.fzf;
          };
          # overrides = self: super: { };
          # hlintCheck.enable = true;
          # hlsCheck.enable = true;
        };
        # haskell-flake doesn't set the default package, but you can do it here.
        packages.default = self'.packages.haskell-flake-test;
      };
    };
}
