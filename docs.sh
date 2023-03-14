#!/usr/bin/env sh

# Renders the docs, prints the location of the docs, opens the docs if possible
#
# Does not run the link checker. That's done in runtest.sh.

nix --option sandbox false \
    build ${OVERRIDE_HASKELL_FLAKE} \
    -L --show-trace \
    github:hercules-ci/flake.parts-website \
    "$@"

DOCSHTML="$PWD/result/options/haskell-flake.html"

echo "Docs rendered to $DOCSHTML"

if [ "$(uname)" == "Darwin" ]; then
  open $DOCSHTML
else 
  if type xdg-open &>/dev/null; then
    xdg-open $DOCSHTML
  fi
fi
