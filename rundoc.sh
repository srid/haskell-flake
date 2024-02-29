#!/usr/bin/env sh

# TODO: Move this dev/flake.nix as flake app

if [ -z "$1" ]; then
  nix run github:srid/emanote -- -L ./doc
else
  # Renders the docs, prints the location of the docs, opens the docs if possible
  #
  # Does not run the link checker. That's done in nixci checks.
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

fi