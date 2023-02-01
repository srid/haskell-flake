# This script is run in a `nix develop` shell by Github Actions.
# 
# You can also run it locally using:
#
#  nix develop --override-input haskell-flake ../ -c ./test.sh
#
# Or, just run `runtests.sh` from project root.

set -xe

# Test haskell devshell (via HLS check)
haskell-language-server

# Setting buildTools.ghcid to null should disable that default buildTool
which ghcid && exit 2 || echo

# Adding a buildTool (fzf, here) should put it in devshell.
which fzf

# TODO
# - overrides
#    - Pin nixpkgs (needed to reliably test overrides): How? permanent flake.lock?
# - checks 
# - multi package