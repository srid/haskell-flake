#!/usr/bin/env sh

# Renders the docs, prints the location of the docs, opens the docs if possible
#
# Does not run the link checker. That's done in runtest.sh.

nix --option sandbox false \
    build --override-input haskell-flake path:${FLAKE} \
    -L --show-trace \
    github:hercules-ci/flake.parts-website \
    "$@"

echo "Docs rendered to $PWD/result/options/haskell-flake.html"

# Works on linux
if type xdg-open &>/dev/null; then
  xdg-open result/options/haskell-flake.html
fi
