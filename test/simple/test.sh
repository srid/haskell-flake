set -euxo pipefail

# First, build the flake
logHeader "Testing nix build"
${NIX} build --override-input haskell-flake path:${FLAKE}
# Run the devshell test script in a nix develop shell.
logHeader "Testing nix devshell"
${NIX} develop --override-input haskell-flake path:${FLAKE} -c ./test-in-devshell.sh
# Test non-devshell features:
# Checks
logHeader "Testing nix flake checks"
${NIX} --option sandbox false \
    build --override-input haskell-flake path:${FLAKE} -L .#check
