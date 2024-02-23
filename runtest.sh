#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash
set -euo pipefail

source ./test/common.sh
nix --version

# The test directory must contain a 'test.sh' file that will be run in that
# directory.
# TODO: Supplant these scripts with Nix. See https://github.com/srid/haskell-flake/issues/241
TESTS=(
  ./example
  ./test/simple
  ./test/with-subdir
  ./test/project-module
  # We run this separately, because it's a bit slow.
  # ./doc
)

for testDir in "${TESTS[@]}" 
do 
  logHeader "Testing $testDir"
  pushd $testDir
  bash ./test.sh
  popd
done

logHeader "All tests passed!"
