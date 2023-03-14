set -euxo pipefail
cabal_project="$(cat ./cabal.project)"
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
  echo "$main_hs" >./haskell-flake-test/src/Main.hs
  echo "$flake_nix" >./flake.nix
}
trap cleanup EXIT

logHeader "Testing source filtering"

function get_drv_path() {
  ${NIX} eval --override-input haskell-flake path:$FLAKE .#packages.$SYSTEM.default.drvPath
}
baseline=$(get_drv_path)

# Eval is idempotent
[[ $(get_drv_path) == $baseline ]]

# Eval is constant under changes to irrelevant files
touch extra-file
git add -N extra-file
[[ $(get_drv_path) == $baseline ]]

test -f ./cabal.project # sanity check
(echo ""; echo "-- irrelevant comment") >>./cabal.project
[[ $(get_drv_path) == $baseline ]]

(echo ""; echo "# irrelevant comment") >>./flake.nix
[[ $(get_drv_path) == $baseline ]]

# A relevant change does cause a .drv change (control check)
f=./haskell-flake-test/src/Main.hs
test -f $f
(echo ""; echo "-- irrelevant comment") >>$f
[[ $(get_drv_path) != $baseline ]]
