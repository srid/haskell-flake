# This script is run in a `nix develop` shell by Github Actions.
# 
# You can also run it locally using:
#
#  nix develop --override-input haskell-flake ../ -c ./test.sh
#
# Or, just run `runtest.sh` from project root.

set -xe

# Test haskell devshell (via HLS check)
haskell-language-server

# Setting buildTools.ghcid to null should disable that default buildTool
which ghcid && exit 2 || echo

# Adding a buildTool (fzf, here) should put it in devshell.
which fzf

# mkShellArgs works
if [[ "$FOO" == "bar" ]]; then 
    echo "$FOO"
else 
    echo "FOO is not bar" 
    exit 2
fi