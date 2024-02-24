default:
    @just --list

# Run example
ex:
    cd ./example && nix run . --override-input haskell-flake ..

test:
    nixci

fmt:
    treefmt