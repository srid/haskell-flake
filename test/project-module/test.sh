source ../common.sh
set -euxo pipefail

# First, build the flake
logHeader "Testing nix build"
nix build ${OVERRIDE_ALL}

logHeader "Testing nix devshell"
nix develop ${OVERRIDE_ALL} -c echo
