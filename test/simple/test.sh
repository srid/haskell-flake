set -euxo pipefail

# First, build the flake
logHeader "Testing nix build"
nix build ${OVERRIDE_HASKELL_FLAKE}
# Run the devshell test script in a nix develop shell.
logHeader "Testing nix devshell"
nix develop ${OVERRIDE_HASKELL_FLAKE} -c ./test-in-devshell.sh
# Test non-devshell features:
# Checks
logHeader "Testing nix flake checks"
nix --option sandbox false \
    build ${OVERRIDE_HASKELL_FLAKE} -L .#check
