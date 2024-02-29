# Common test library of functions and variables
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function logHeader {
  echo -e "\n||| $@"
}

nix --version

SYSTEM=$(nix eval --impure --expr builtins.currentSystem)

DIR_OF_COMMON_SH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HASKELL_FLAKE=${DIR_OF_COMMON_SH}/..
OVERRIDE_HASKELL_FLAKE="--override-input haskell-flake path:${HASKELL_FLAKE}"

# Let's pin both nixpkgs and flake-parts across all tests, to save up on CI time.
NIXPKGS_REV=$(jq -r '.nodes."nixpkgs".locked.rev' < ${HASKELL_FLAKE}/example/flake.lock)
NIXPKGS_URL="github:nixos/nixpkgs/${NIXPKGS_REV}"
OVERRIDE_NIXPKGS="--override-input nixpkgs ${NIXPKGS_URL}"
FLAKE_PARTS_REV=$(jq -r '.nodes."flake-parts".locked.rev' < ${HASKELL_FLAKE}/example/flake.lock)
OVERRIDE_FLAKE_PARTS="--override-input flake-parts github:hercules-ci/flake-parts/${FLAKE_PARTS_REV}"

OVERRIDE_ALL="${OVERRIDE_HASKELL_FLAKE} ${OVERRIDE_FLAKE_PARTS} ${OVERRIDE_NIXPKGS}"

currentver="$(nix eval --raw --expr builtins.nixVersion)"
requiredver="2.14.1"
if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ];
then 
  echo
else
  echo "!!!! Your Nix version is old ($currentver)."
  exit 2
fi
