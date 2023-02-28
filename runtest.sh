set -e

if [ "$(uname)" == "Darwin" ]; then
    SYSTEM=aarch64-darwin
    function logHeader {
        echo "\n||| $@"
    }
else
    SYSTEM=x86_64-linux
    function logHeader {
        echo -e "\n||| $@"
    }
fi

FLAKE=$(pwd)

# A Nix bug causes incorrect self when in a sub-flake.
# https://github.com/NixOS/nix/issues/7263
# Workaround: copy ./test somewhere outside of this Git repo.
TESTDIR=$(mktemp -d)
trap 'rm -fr "$TESTDIR"' EXIT
cp -r ./test/* "$TESTDIR"
cd "$TESTDIR"
pwd

# First, build the flake
logHeader "Testing nix build"
nix build --override-input haskell-flake path:${FLAKE}
# Run the devshell test script in a nix develop shell.
logHeader "Testing nix devshell"
nix develop --override-input haskell-flake path:${FLAKE} -c ./test.sh
# Test non-devshell features:
# Checks
logHeader "Testing nix flake checks"
nix --option sandbox false \
    build --override-input haskell-flake path:${FLAKE} -L .#check

#logHeader "Testing docs"
#nix build --override-input haskell-flake path:${FLAKE} \
#    --option log-lines 1000 --show-trace \
#    github:hercules-ci/flake.parts-website#checks.${SYSTEM}.linkcheck

logHeader "All tests passed!"
