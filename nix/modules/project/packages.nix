# Definition of the `haskellProjects.${name}` submodule's `config`
project@{ lib, pkgs, ... }:
{
  options = {
    packages =
      import ./package.nix {
        inherit project lib pkgs;
        description = ''
          Set of local packages in the project repository.

          If you have a `cabal.project` file (under `projectRoot`), those packages
          are automatically discovered. Otherwise, the top-level .cabal file is
          used to discover the only local package.
        
          haskell-flake currently supports a limited range of syntax for
          `cabal.project`. Specifically it requires an explicit list of package
          directories under the "packages" option.
        '';
      };
  };
}
