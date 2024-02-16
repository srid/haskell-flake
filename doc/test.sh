source ../test/common.sh

nix build ${OVERRIDE_HASKELL_FLAKE} \
    --option log-lines 1000 --show-trace \
    "github:hercules-ci/flake.parts-website#checks.${SYSTEM}.linkcheck"