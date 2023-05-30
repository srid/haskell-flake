# Definition of the `haskellProjects.${name}` submodule's `config`
{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo;

  devShellSubmodule = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        description = ''
          Whether to enable a development shell for the project.
        '';
        default = true;
      };
      tools = mkOption {
        type = functionTo (types.attrsOf (types.nullOr types.package));
        description = ''
          Build tools for developing the Haskell project.

          These tools are merged with the haskell-flake defaults defined in the
          `defaults.devShell.tools` option. Set the value to `null` to remove
          that default tool.
        '';
        default = hp: { };
      };
      extraLibraries = mkOption {
        type = functionTo (types.attrsOf (types.nullOr types.package));
        description = ''
          Extra Haskell libraries available in the shell's environment.
          These can be used in the shell's `runghc` and `ghci` for instance.

          The argument is the Haskell package set.

          The return type is an attribute set for overridability and syntax, as only the values are used.
        '';
        default = hp: { };
        defaultText = lib.literalExpression "hp: { }";
        example = lib.literalExpression "hp: { inherit (hp) releaser; }";
      };

      mkShellArgs = mkOption {
        type = types.attrsOf types.raw;
        description = ''
          Extra arguments to pass to `pkgs.mkShell`.
        '';
        default = { };
        example = ''
          {
            shellHook = \'\'
              # Re-generate .cabal files so HLS will work (per hie.yaml)
              ''${pkgs.findutils}/bin/find -name package.yaml -exec hpack {} \;
            \'\';
          };
        '';
      };
    };
  };
in
{
  imports = [
    ./hls-check.nix
  ];
  options = {
    devShell = mkOption {
      type = devShellSubmodule;
      description = ''
        Development shell configuration
      '';
      default = { };
    };
    outputs.devShell = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The development shell derivation generated for this project.
      '';
    };
  };
  config =
    let
      inherit (config.outputs) finalPackages;

      nativeBuildInputs = lib.attrValues (
        config.defaults.devShell.tools finalPackages //
        config.devShell.tools finalPackages
      );
      mkShellArgs = config.devShell.mkShellArgs // {
        nativeBuildInputs = (config.devShell.mkShellArgs.nativeBuildInputs or [ ]) ++ nativeBuildInputs;
      };
      devShell = finalPackages.shellFor (mkShellArgs // {
        packages = p:
          let
            localPackages = (lib.filterAttrs (k: v: v.local.toCurrentProject) config.packages);
          in
          map
            (name: p."${name}")
            (lib.attrNames localPackages);
        withHoogle = true;
        extraDependencies = p:
          let o = mkShellArgs.extraDependencies or (_: { }) p;
          in o // {
            libraryHaskellDepends = o.libraryHaskellDepends or [ ]
              ++ builtins.attrValues (config.devShell.extraLibraries p);
          };
      });

    in
    {
      outputs = {
        inherit devShell;
      };
    };
}
