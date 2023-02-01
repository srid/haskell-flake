FLAKE=$(pwd)
cd ./test
# First, build the flake.
nix build --override-input haskell-flake path:${FLAKE}
# Run the test script in a nix develop shell.
nix develop --override-input haskell-flake path:${FLAKE} -c ./test.sh
