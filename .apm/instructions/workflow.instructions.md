---
description: Workflow commands for the /do pipeline
applyTo: "**"
---

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
