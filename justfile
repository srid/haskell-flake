default:
    @just --list

# Run example
ex:
    cd ./example && nix run . --override-input haskell-flake ..

# Run the checks locally using nixci
check:
    nixci

# Auto-format the Nix files in project tree
fmt:
    treefmt

# Open haskell-flake docs live preview
docs:
    cd ./doc && nix run

# Open flake.parts docs, previewing local haskell-flake version
docs-flake-parts:
    cd ./doc && nix run .#flake-parts
