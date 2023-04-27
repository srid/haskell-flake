{ debug ? false, ... }:

{
  traceDebug = msg:
    if debug then
      builtins.trace ("DEBUG[haskell-flake]: " + msg)
    else
      x: x;

  traceWarning = msg:
    builtins.trace ("WARNING[haskell-flake]: " + msg);

  throwError = msg: builtins.throw ''
    ERROR[haskell-flake]: ${msg}
  '';
}
