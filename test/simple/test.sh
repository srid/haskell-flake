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
