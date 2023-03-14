source ../../test/common.sh

nix eval -I nixpkgs=flake:${NIXPKGS_URL} \
    --impure --expr 'import ./parser_tests.nix {}'