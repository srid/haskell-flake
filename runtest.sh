#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash
set -euo pipefail

source ./test/common.sh
nix --version

# The test directory must contain a 'test.sh' file that will be run in that
# directory.
TESTS=(
  ./nix/haskell-parsers
  ./example
  ./test/simple
  ./test/with-subdir
  ./test/project-module
  # FIXME: why is doc failing on projectRoot option?
  # ./doc
)

for testDir in "${TESTS[@]}" 
do 
  logHeader "Testing $testDir"
  pushd $testDir
  $SHELL ./test.sh
  popd
done

logHeader "All tests passed!"
