set -e

FLAKE=$(pwd)
cd ./test

# First, build the flake.
echo -e "\n||| Testing nix build"
nix build --override-input haskell-flake path:${FLAKE}
# Run the devshell test script in a nix develop shell.
echo -e "\n||| Testing nix devshell"
nix develop --override-input haskell-flake path:${FLAKE} -c ./test.sh
# Test non-devshell features:
# Checks
echo -e "\n||| Testing nix flake checks"
nix --option sandbox false \
    build --override-input haskell-flake path:${FLAKE} -L .#check

echo -e "\n||| Testing docs"
nix build --override-input haskell-flake path:${FLAKE} \
    --option log-lines 1000 --show-trace \
    github:hercules-ci/flake.parts-website#checks.x86_64-linux.linkcheck

echo -e "\n||| All tests passed!"