{ config, lib, mkCabalSettingOptions, ... }:

let
  inherit (lib)
    types;
in
{
  # TODO: Instead of baking this in haskell-flake, can we instead allow the
  # user to define these 'custom' options? Are NixOS modules flexible enough
  # for that?
  options = mkCabalSettingOptions {
    inherit config;
    name = "removeReferencesTo";
    type = types.listOf types.package;
    description = ''
      Packages to remove references to.

      This is useful to ditch unnecessary data dependencies from your Haskell
      executable so as to reduce its closure size.
      
      cf. 
      - https://github.com/NixOS/nixpkgs/pull/204675
      - https://srid.ca/remove-references-to
    '';
    impl = disallowedReferences: drv:
      drv.overrideAttrs (old: rec {
        inherit disallowedReferences;
        postInstall = (old.postInstall or "") + ''
          ${lib.concatStrings (map (e: "echo Removing reference to: ${e}\n") disallowedReferences)}
          ${lib.concatStrings (map (e: "remove-references-to -t ${e} $out/bin/*\n") disallowedReferences)}
        '';
      });
  };
}
