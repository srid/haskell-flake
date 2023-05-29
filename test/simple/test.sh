source ../common.sh
set -euxo pipefail

# First, build the flake
logHeader "Testing nix build"
nix build ${OVERRIDE_ALL}

# Test defaults.settings module behaviour, viz: separateBinOutput
test -f result-bin/bin/haskell-flake-test

# Run the devshell test script in a nix develop shell.
logHeader "Testing nix devshell"
nix develop ${OVERRIDE_ALL} -c ./test-in-devshell.sh
# Run the cabal executable as flake app
logHeader "Testing nix flake app (cabal exe)"
nix run ${OVERRIDE_ALL} .#app1
# Test non-devshell features:
# Checks
logHeader "Testing nix flake checks"
nix --option sandbox false build \
    --no-link --print-out-paths \
    ${OVERRIDE_ALL} -L .#check
