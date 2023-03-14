
nix build --override-input haskell-flake path:${FLAKE} \
    --option log-lines 1000 --show-trace \
    "github:hercules-ci/flake.parts-website#checks.${SYSTEM}.linkcheck"