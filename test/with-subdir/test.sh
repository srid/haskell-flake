source ../common.sh
set -euxo pipefail
cabal_project="$(cat ./cabal.project)"
cabal_file="$(cat ./haskell-flake-test/haskell-flake-test.cabal)"
main_hs="$(cat ./haskell-flake-test/src/Main.hs)"
flake_nix="$(cat ./flake.nix)"
function cleanup() {
  r=$?
  if [[ $r != 0 ]]; then
    echo "Test failed!"
    echo 'See failed command above "cleanup"'
    set +x
  fi
  git rm -f extra-file
  echo "$cabal_project" >./cabal.project
  echo "$cabal_file" >./haskell-flake-test/haskell-flake-test.cabal
  echo "$main_hs" >./haskell-flake-test/src/Main.hs
  echo "$flake_nix" >./flake.nix
}
trap cleanup EXIT

logHeader "Testing source filtering"

function get_drv_path() {
  nix eval ${OVERRIDE_ALL} .#packages.$SYSTEM.default.drvPath
}

# Used to test that IFD is not run unnecessarily.
function get_cabal2nixDeriver_drv_hash() {
  nix eval ${OVERRIDE_ALL} .#packages.$SYSTEM.default.cabal2nixDeriver.drvPath
}
baseline=$(get_drv_path)
baseline_cabal2nix=$(get_cabal2nixDeriver_drv_hash)

# Eval is idempotent
[[ $(get_drv_path) == $baseline ]]
[[ $(get_cabal2nixDeriver_drv_hash) == $baseline_cabal2nix ]]

# Eval is constant under changes to irrelevant files
touch extra-file
git add -N extra-file
[[ $(get_drv_path) == $baseline ]]
[[ $(get_cabal2nixDeriver_drv_hash) == $baseline_cabal2nix ]]

test -f ./cabal.project # sanity check
(echo ""; echo "-- irrelevant comment") >>./cabal.project
[[ $(get_drv_path) == $baseline ]]
[[ $(get_cabal2nixDeriver_drv_hash) == $baseline_cabal2nix ]]

(echo ""; echo "# irrelevant comment") >>./flake.nix
[[ $(get_drv_path) == $baseline ]]
[[ $(get_cabal2nixDeriver_drv_hash) == $baseline_cabal2nix ]]

# A relevant change to Haskell source causes a .drv change (control check)
# But no cabal2nix re-eval
f=./haskell-flake-test/src/Main.hs
test -f $f
(echo ""; echo "-- irrelevant comment") >>$f
[[ $(get_drv_path) != $baseline ]]
[[ $(get_cabal2nixDeriver_drv_hash) == $baseline_cabal2nix ]]

# A relevant change to .cabal file causes cabal2nix re-eval
f=./haskell-flake-test/haskell-flake-test.cabal
test -f $f
(echo ""; echo "-- irrelevant comment in cabal") >>$f
[[ $(get_drv_path) != $baseline ]]
[[ $(get_cabal2nixDeriver_drv_hash) != $baseline_cabal2nix ]]
