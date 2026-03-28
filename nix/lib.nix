# Standalone API for using haskell-flake without flake-parts.
#
# In a flake:
#   let
#     project = (haskell-flake.lib { inherit pkgs; }).evalHaskellProject {
#       projectRoot = self;
#     };
#   in project.packages.mypackage.package
#
# Without flakes:
#   let
#     project = (import /path/to/haskell-flake/nix/lib.nix { inherit pkgs; }).evalHaskellProject {
#       projectRoot = ./.;
#     };
#   in project.packages.mypackage.package
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
