# TODO: This is being moved to a flake check.
# Currently doing only what's not being done in the flake check (via nixci).

source ../common.sh
set -euxo pipefail

rm -f result result-bin

# Test defaults.settings module behaviour, viz: haddock
nix build ${OVERRIDE_ALL} .#default^doc && {
    echo "ERROR: dontHaddock (from defaults.settings) not in effect"
    exit 1
}

# Run the devshell test script in a nix develop shell.
logHeader "Testing nix devshell"
nix develop ${OVERRIDE_ALL} -c ./test-in-devshell.sh
