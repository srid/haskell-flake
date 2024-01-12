{ name, ... }:

{
  traceDebug = msg:
    builtins.traceVerbose ("DEBUG[haskell-flake] [${name}]: " + msg);

  traceWarning = msg:
    builtins.trace ("WARNING[haskell-flake] [${name}]: " + msg);

  throwError = msg: builtins.throw ''
    ERROR[haskell-flake] [${name}]: ${msg}
  '';
}
