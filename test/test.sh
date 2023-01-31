# This script is run in `nix develop` shell by Github Actions.

set -xe

# Test haskell devshell (via HLS check)
haskell-language-server

# Setting buildTools.ghcid to null should disable that default buildTool
which ghcid && exit 2 || echo

# Adding a buildTool (fzf, here) should put it in devshell.
which fzf
