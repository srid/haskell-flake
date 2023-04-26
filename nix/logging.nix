{ lib, debug, ... }:

{
  traceDebug = k: f:
    if debug then
      (x: lib.pipe x [
        (builtins.trace ("DEBUG[haskell-flake]: " + k + " " + f x))
      ])
    else
      (x: x);
}
