#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash
set -euo pipefail

source ./test/common.sh

# The test directory must contain a 'test.sh' file that will be run in that
# directory.
TESTS=(
  ./nix/find-haskell-paths
  ./test/simple
  ./test/with-subdir
  ./doc
)

for testDir in "${TESTS[@]}" 
do 
  logHeader "Testing $testDir"
  pushd $testDir
  $SHELL ./test.sh
  popd
done

logHeader "All tests passed!"