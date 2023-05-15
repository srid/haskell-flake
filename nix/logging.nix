{ name, debug ? false, ... }:

{
  traceDebug = msg:
    if debug then
      builtins.trace ("DEBUG[haskell-flake] [${name}]: " + msg)
    else
      x: x;

  traceWarning = msg:
    builtins.trace ("WARNING[haskell-flake] [${name}]: " + msg);

  throwError = msg: builtins.throw ''
    ERROR[haskell-flake] [${name}]: ${msg}
  '';
}
