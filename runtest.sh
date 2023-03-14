#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash
set -euxo pipefail

source ./test/common.sh

# Before anything, run the main haskell-flake tests
logHeader "Testing ./nix/find-haskell-paths"
pushd ./nix/find-haskell-paths
$SHELL ./test.sh
popd

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