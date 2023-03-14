# Common test library of functions and variables
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function logHeader {
  echo -e "\n||| $@"
}

if [ "$(uname)" == "Darwin" ]; then
  SYSTEM=aarch64-darwin
else
  SYSTEM=x86_64-linux
fi

DIR_OF_COMMON_SH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HASKELL_FLAKE=${DIR_OF_COMMON_SH}/..
OVERRIDE_HASKELL_FLAKE="--override-input haskell-flake path:${HASKELL_FLAKE}"
OVERRIDE_NIXPKGS="--override-input nixpkgs github:nixos/nixpkgs/bb31220cca6d044baa6dc2715b07497a2a7c4bc7"

# Waiting on github.com/nixbuild/nix-quick-install-action to support 2.13+
# We use newer Nix for:
# - https://github.com/NixOS/nix/issues/7263
# - https://github.com/NixOS/nix/issues/7026
nix build --no-link github:nixos/nix/2.14.1
export PATH=$(nix eval --raw github:nixos/nix/2.14.1#default.outPath)/bin:$PATH
echo $PATH
nix --version

