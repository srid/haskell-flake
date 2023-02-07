# A flake-parts module for Haskell cabal projects.
{ self, config, lib, flake-parts-lib, ... }:

let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    mkOption
    types;
  inherit (types)
    functionTo
    raw;
in
{
  options = {
    perSystem = mkPerSystemOption
      ({ config, self', inputs', pkgs, system, ... }:
        let
          hlsCheckSubmodule = types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                description = ''
                  Whether to enable a flake check to verify that HLS works.
                  
                  This is equivalent to `nix develop -i -c haskell-language-server`.

                  Note that, HLS will try to access the network through Cabal (see 
                  <https://github.com/haskell/haskell-language-server/issues/3128>),
                  therefore sandboxing must be disabled when evaluating this
                  check.
                '';
                default = false;
              };

            };
          };
          packageSubmodule = with types; submodule {
            options = {
              root = mkOption {
                type = path;
                description = "Path to Haskell package where the `.cabal` file lives";
              };
            };
          };
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
                '';
                default = hp: { };
                defaultText = ''
                  Build tools useful for Haskell development are included by default.
                '';
              };
              hlsCheck = mkOption {
                default = { };
                type = hlsCheckSubmodule;
                description = ''
                  A [check](flake-parts.html#opt-perSystem.checks) to make sure that your IDE will work.
                '';
              };
            };
          };
          projectSubmodule = types.submodule projectSubmoduleF;
          projectSubmoduleOptions = {
            imports = mkOption {
              # type = types.listOf projectSubmodule; # (types.attrsOf types.raw);
              type = types.listOf (types.attrsOf types.raw);
              description = ''
                haskell-flake project modules to import.
              '';
              default = [ ];
            };
            haskellPackages = mkOption {
              type = types.attrsOf raw;
              description = ''
                Which Haskell package set / compiler to use.

                You can effectively select the GHC version here. 
                  
                To get the appropriate value, run:

                    nix-env -f "<nixpkgs>" -qaP -A haskell.compiler

                And then, use that in `pkgs.haskell.packages.ghc<version>`
              '';
              example = "pkgs.haskell.packages.ghc924";
              default = pkgs.haskellPackages;
              defaultText = lib.literalExpression "pkgs.haskellPackages";
            };
            source-overrides = mkOption {
              type = types.attrsOf types.path;
              description = ''Package overrides given new source path'';
              default = { };
            };
            overrides = mkOption {
              type = functionTo (functionTo (types.lazyAttrsOf raw));
              description = ''
                Overrides for the Cabal project
                
                For handy functions, see <https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix>
              '';
              default = self: super: { };
              defaultText = lib.literalExpression "self: super: { }";
            };
            packages = mkOption {
              type = types.lazyAttrsOf packageSubmodule;
              description = ''
                Attrset of local packages in the project repository.

                Autodetected by default by looking for `.cabal` files in sub-directories.
              '';
              default =
                lib.mapAttrs
                  (_: value: { root = value; })
                  (lib.filesystem.haskellPathsInDir self);
              defaultText = lib.literalMD "autodiscovered by reading `self` files.";
            };
            devShell = mkOption {
              type = devShellSubmodule;
              description = ''
                Development shell configuration
              '';
              default = { };
            };
            outputs = mkOption {
              type = types.attrsOf types.raw;
              description = ''
                The flake outputs generated for this project.

                This is an internal option, not meant to be set by the user.
              '';
            };
          };
          projectSubmoduleF = args@{ name, config, lib, ... }: {
            options = projectSubmoduleOptions;
            config = import ./haskell-project.nix (args // {
              inherit self pkgs projectSubmoduleOptions;
            });
          };
        in
        {
          options.haskellProjects = mkOption {
            description = "Haskell projects";
            type = types.attrsOf projectSubmodule;
          };
        });
  };

  config = {
    perSystem = { config, self', lib, inputs', pkgs, ... }:
      let
        # Like mapAttrs, but merges the values (also attrsets) of the resulting attrset.
        flatAttrMap = f: attrs: lib.mkMerge (lib.attrValues (lib.mapAttrs f attrs));
      in
      {
        packages =
          flatAttrMap (_: project: project.outputs.packages) config.haskellProjects;
        devShells =
          flatAttrMap
            (_: project:
              lib.optionalAttrs project.devShell.enable project.outputs.devShells)
            config.haskellProjects;
        checks =
          flatAttrMap
            (_: project:
              lib.optionalAttrs project.devShell.enable project.outputs.checks)
            config.haskellProjects;
      };
  };
}
