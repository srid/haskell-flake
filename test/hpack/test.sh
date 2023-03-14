source ../common.sh
set -euxo pipefail

# First, build the flake
logHeader "Testing nix build"
nix build ${OVERRIDE_HASKELL_FLAKE}
# Run the devshell test script in a nix develop shell.
logHeader "Testing nix devshell"
nix develop ${OVERRIDE_HASKELL_FLAKE} -c echo
