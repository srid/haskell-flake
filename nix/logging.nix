{ name, ... }:

{
  # traceDebug uses traceVerbose; and is no-op on Nix versions below 2.10
  traceDebug =
    if builtins.compareVersions "2.10" builtins.nixVersion < 0
    then msg: builtins.traceVerbose ("DEBUG[haskell-flake] [${name}]: " + msg)
    else x: x;

  traceWarning = msg:
    builtins.trace ("WARNING[haskell-flake] [${name}]: " + msg);

  throwError = msg: builtins.throw ''
    ERROR[haskell-flake] [${name}]: ${msg}
  '';
}
