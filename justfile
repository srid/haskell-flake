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
