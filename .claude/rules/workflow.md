---
paths:
  - "**"
---

## Dev shell

This project's devshell is provided by a separate flake in `./dev`. Enter it with:

```sh
nix develop ./dev --override-input haskell-flake .
```

Or prefix commands with:

```sh
nix develop ./dev --override-input haskell-flake . -c <command>
```

See `.envrc` for details.

## Check command

```sh
nix flake check
```

Fast static-correctness gate. Runs the flake's built-in checks (build all packages and run tests).

## Format command

```sh
just fmt
```

## CI command

```sh
vira ci
```

If running with local (uncommitted) changes, use `vira ci -b` instead.

Verify by checking exit code 0.
