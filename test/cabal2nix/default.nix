{ mkDerivation, base, lib, random }:
mkDerivation {
  pname = "haskell-flake-test";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base random ];
  license = "unknown";
  mainProgram = "haskell-flake-test";
}
