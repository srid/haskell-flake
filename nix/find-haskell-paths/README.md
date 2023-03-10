# `find-haskell-paths`

`find-haskell-paths` is a superior alternative to nixpkgs' [`haskellPathsInDir`](https://github.com/NixOS/nixpkgs/blob/f991762ea1345d850c06cd9947700f3b08a12616/lib/filesystem.nix#L18).

- It locates packages based on the "packages" field of `cabal.project` file if it exists (otherwise it returns the top-level package).
- It supports `hpack`, thus works with `package.yaml` even if no `.cabal` file exists.

## Limitations

- Glob patterns in `cabal.project` are not supported yet. Feel free to open a PR improving the parser to support them.
