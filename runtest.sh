#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash
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


# Waiting on github.com/nixbuild/nix-quick-install-action to support 2.13+
# We use newer Nix for:
# - https://github.com/NixOS/nix/issues/7263
# - https://github.com/NixOS/nix/issues/7026
NIX="nix run github:nixos/nix/2.14.1 --"
${NIX} --version

# Before anything, run the main haskell-flake tests
logHeader "Testing find-haskell-paths' parser"
${NIX} eval -I nixpkgs=flake:github:nixos/nixpkgs/bb31220cca6d044baa6dc2715b07497a2a7c4bc7 \
    --impure --expr 'import ./nix/find-haskell-paths/parser_tests.nix {}'


FLAKE=$(pwd)

export -f logHeader
export NIX FLAKE SYSTEM

pushd ./test/with-subdir
$SHELL ./test.sh
popd

pushd ./test/simple
$SHELL ./test.sh
popd 

logHeader "Testing docs"
nix build --override-input haskell-flake path:${FLAKE} \
    --option log-lines 1000 --show-trace \
    "github:hercules-ci/flake.parts-website#checks.${SYSTEM}.linkcheck"

logHeader "All tests passed!"