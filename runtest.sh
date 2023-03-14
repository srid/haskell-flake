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
export PATH=$(nix eval --raw github:nixos/nix/2.14.1#default.outPath)/bin:$PATH
nix --version

# Before anything, run the main haskell-flake tests
logHeader "Testing ./nix/find-haskell-paths"
pushd ./nix/find-haskell-paths
$SHELL ./test.sh
popd


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
pushd ./doc
$SHELL ./test.sh
popd

logHeader "All tests passed!"