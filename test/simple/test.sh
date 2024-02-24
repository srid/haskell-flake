source ../common.sh
set -euxo pipefail

rm -f result result-bin

# First, build the flake
logHeader "Testing nix build"
nix build ${OVERRIDE_ALL}

# Test defaults.settings module behaviour, viz: haddock
nix build ${OVERRIDE_ALL} .#default^doc && {
    echo "ERROR: dontHaddock (from defaults.settings) not in effect"
    exit 1
}

# Run the devshell test script in a nix develop shell.
logHeader "Testing nix devshell"
nix develop ${OVERRIDE_ALL} -c ./test-in-devshell.sh
# Run the cabal executable as flake app
logHeader "Testing nix flake app (cabal exe)"
nix run ${OVERRIDE_ALL} .#app1
# Test non-devshell features:
# Checks
logHeader "Testing nix flake checks"
nix --option sandbox false flake check ${OVERRIDE_ALL}
