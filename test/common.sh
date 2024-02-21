# Common test library of functions and variables
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function logHeader {
  echo -e "\n||| $@"
}

SYSTEM=$(nix show-config | grep 'system =' | nix run nixpkgs#gawk '{print $3}')

DIR_OF_COMMON_SH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HASKELL_FLAKE=${DIR_OF_COMMON_SH}/..
OVERRIDE_HASKELL_FLAKE="--override-input haskell-flake path:${HASKELL_FLAKE}"

# Let's pin both nixpkgs and flake-parts across all tests, to save up on CI time.
NIXPKGS_URL="github:nixos/nixpkgs/bb31220cca6d044baa6dc2715b07497a2a7c4bc7"
OVERRIDE_NIXPKGS="--override-input nixpkgs ${NIXPKGS_URL}"
OVERRIDE_FLAKE_PARTS="--override-input flake-parts github:hercules-ci/flake-parts/7c7a8bce3dffe71203dcd4276504d1cb49dfe05f"

OVERRIDE_ALL="${OVERRIDE_HASKELL_FLAKE} ${OVERRIDE_FLAKE_PARTS} ${OVERRIDE_NIXPKGS}"

currentver="$(nix eval --raw --expr builtins.nixVersion)"
requiredver="2.14.1"
if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ];
then 
  echo
else
  echo "!!!! Your Nix version is old ($currentver). Using newer Nix from github:nixos/nix/2.14.1"
  # We use newer Nix for:
  # - https://github.com/NixOS/nix/issues/7263
  # - https://github.com/NixOS/nix/issues/7026
  nix build --no-link github:nixos/nix/2.14.1
  export PATH=$(nix eval --raw github:nixos/nix/2.14.1#default.outPath)/bin:$PATH
fi

nix --version