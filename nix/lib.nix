# Standalone API for using haskell-flake without flake-parts.
#
# Usage:
#   let
#     project = (import haskell-flake.lib { inherit pkgs; }).evalHaskellProject {
#       projectRoot = ./.;
#       modules = [{ settings.mypkg.haddock = false; }];
#     };
#   in project.packages.mypkg.package
{ pkgs, lib ? pkgs.lib }:

{
  # Evaluate a haskell-flake project configuration and return its outputs.
  #
  # Returns: { finalOverlay, finalPackages, packages, apps, devShell, checks }
  evalHaskellProject =
    { projectRoot
    , name ? "default"
    , modules ? [ ]
    }:
    (lib.evalModules {
      specialArgs = { inherit pkgs name; };
      modules = [
        ./modules/project
        { inherit projectRoot; }
      ] ++ modules;
    }).config.outputs;
}
