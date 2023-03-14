
nix eval -I nixpkgs=flake:github:nixos/nixpkgs/bb31220cca6d044baa6dc2715b07497a2a7c4bc7 \
    --impure --expr 'import ./parser_tests.nix {}'