{ lib, old, ... }:
let
  inherit (lib)
    literalMD
    mkOption
    types
  ;

  # TODO: we do hardcode the defaults from `nixpkgs` `pkgs/development/haskell-modules/generic-builder.nix`. Is that necessary?
  defaultText = literalMD "The value as it was defined before. This may come from `callCabal2nix` or a previously applied overlay layer.";

in
{
  options = {
    enableLibraryProfiling = mkOption {
      type = types.bool;
      default = old.enableLibraryProfiling or true;
      inherit defaultText;
      description = ''
        Whether or not to compile the library with profiling enabled, in addition to the regular compilation. This allows packages that depend on the library to be built with profiling enabled, but takes a bit more time to build.

        Alternatively, this can be used to disable profiling in cases where it is not supported. This may happen on weakly supported platforms, but should be rare.
      '';
    };
    broken = mkOption {
      type = types.bool;
      default = old.broken or false;
      inherit defaultText;
      description = ''
        Packages that are known to be broken in certain configurations (host platform, etc), can be marked as such, to prevent users from attempting to build something that can't be built.
      '';
    };
  };
}