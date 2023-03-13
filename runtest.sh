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

(
  cd ./test/with-subdir
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

)

pushd ./test/simple

# First, build the flake
logHeader "Testing nix build"
${NIX} build --override-input haskell-flake path:${FLAKE}
# Run the devshell test script in a nix develop shell.
logHeader "Testing nix devshell"
${NIX} develop --override-input haskell-flake path:${FLAKE} -c ./test.sh
# Test non-devshell features:
# Checks
logHeader "Testing nix flake checks"
${NIX} --option sandbox false \
    build --override-input haskell-flake path:${FLAKE} -L .#check

popd 

logHeader "Testing docs"
nix build --override-input haskell-flake path:${FLAKE} \
    --option log-lines 1000 --show-trace \
    "github:hercules-ci/flake.parts-website#checks.${SYSTEM}.linkcheck"

logHeader "All tests passed!"