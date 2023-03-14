set -euxo pipefail

# First, build the flake
logHeader "Testing nix build"
nix build --override-input haskell-flake path:${FLAKE}
# Run the devshell test script in a nix develop shell.
logHeader "Testing nix devshell"
nix develop --override-input haskell-flake path:${FLAKE} -c ./test-in-devshell.sh
# Test non-devshell features:
# Checks
logHeader "Testing nix flake checks"
nix --option sandbox false \
    build --override-input haskell-flake path:${FLAKE} -L .#check
