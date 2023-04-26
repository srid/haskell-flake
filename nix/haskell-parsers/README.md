# `haskell-parsers`

`haskell-parsers` provides parsers for Haskell associated files: cabal and cabal.project. It provides:

- **`findPackagesInCabalProject`**: a superior alternative to nixpkgs' [`haskellPathsInDir`](https://github.com/NixOS/nixpkgs/blob/f991762ea1345d850c06cd9947700f3b08a12616/lib/filesystem.nix#L18).
  - It locates packages based on the "packages" field of `cabal.project` file if it exists (otherwise it returns the top-level package).
- **`getCabalExecutables`**: a function to extract executables from a `.cabal` file.

## Limitations

- Glob patterns in `cabal.project` are not supported yet. Feel free to open a PR improving the parser to support them.
- https://github.com/srid/haskell-flake/issues/113
