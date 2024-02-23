SYSTEM=$(nix eval --impure --expr builtins.currentSystem)
HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

nix build --override-input haskell-flake ${HERE}/.. \
    --option log-lines 1000 --show-trace \
    "github:hercules-ci/flake.parts-website#checks.${SYSTEM}.linkcheck"