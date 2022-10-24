# A flake-parts module for Haskell cabal projects.
{ self, config, lib, flake-parts-lib, ... }:

let
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    mkPerSystemOption;
  inherit (lib)
    mkOption
    mkDefault
    types;
  inherit (types)
    functionTo
    raw;
in
{
  options = {
    perSystem = mkPerSystemOption
      ({ config, self', inputs', pkgs, system, ... }: {
        options.haskellProjects = mkOption {
          description = "Haskell projects";
          type = types.attrsOf (types.submodule {
            options = {
              haskellPackages = mkOption {
                type = types.attrsOf raw;
                description = ''
                  Which Haskell package set / compiler to use.

                  You can effectively select the GHC version here. 
                  
                  To get the appropriate value, run:
                    nix-env -f "<nixpkgs>" -qaP -A haskell.compiler
                  And that use that in `pkgs.haskell.packages.ghc<version>`
                '';
                example = "pkgs.haskell.packages.ghc924";
                default = pkgs.haskellPackages;
              };
              name = mkOption {
                type = types.str;
                description = ''Name of the cabal package ("foo" if foo.cabal)'';
              };
              root = mkOption {
                type = types.path;
                description = ''Path to the Cabal project root'';
              };
              source-overrides = mkOption {
                type = types.attrsOf types.path;
                description = ''Package overrides given new source path'';
                default = { };
              };
              overrides = mkOption {
                type = functionTo (functionTo (types.lazyAttrsOf raw));
                description = ''Overrides for the Cabal project'';
                default = self: super: { };
              };
              # TODO: This option will go away after #7
              modifier = mkOption {
                type = functionTo types.package;
                description = ''
                  Modifier for the Cabal project

                  Typically you want to use `overrideCabal` to override various
                  attributes of Cabal project.
              
                  For examples on what is possible, see:
                  https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix
                '';
                default = drv: drv;
              };
              buildTools = mkOption {
                type = functionTo (types.attrsOf (types.nullOr types.package));
                description = ''Build tools for your Haskell package (available only in nix shell).'';
                default = hp: { };
                defaultText = ''Build tools useful for Haskell development are included by default.'';
              };
              hlsCheck = mkOption {
                type = types.submodule {
                  options = {
                    enable = mkOption {
                      type = types.bool;
                      description = ''
                        Whether to enable a flake check to verify that HLS works.
                  
                        This is equivalent to `nix develop -i -c haskell-language-server`.

                        Note that, HLS will try to access the network through Cabal (see 
                        https://github.com/haskell/haskell-language-server/issues/3128),
                        therefore sandboxing must be disabled when evaluating this
                        check.
                      '';
                      default = false;
                    };

                  };
                };
              };
              hlintCheck = mkOption {
                type = types.submodule {
                  options = {
                    enable = mkOption {
                      type = types.bool;
                      description = "Whether to add a flake check to run hlint";
                      default = false;
                    };
                    dirs = mkOption {
                      type = types.listOf types.str;
                      description = "Relative path strings from `root` to directories that should be checked with hlint";
                      default = [ "." ];
                    };
                  };
                };
              };
            };
          });
        };
      });
  };
  config = {
    perSystem = { config, self', inputs', pkgs, ... }:
      let
        # Like pkgs.runCommand but runs inside nix-shell with a mutable project directory.
        #
        # It currenty respects only the nativeBuildInputs (and no shellHook for
        # instance), which seems sufficient for our purposes. We also set $HOME and
        # make the project root mutable, because those are expected when running
        # something in a project shell (it is indeed the case with HLS).
        runCommandInSimulatedShell = devShell: projectRoot: name: attrs: command:
          pkgs.runCommand name (attrs // { nativeBuildInputs = devShell.nativeBuildInputs; })
            ''
              # Set pipefail option for safer bash
              set -euo pipefail

              # Copy project root to a mutable area
              # We expect "command" to mutate it.
              export HOME=$TMP
              cp -R ${projectRoot} $HOME/project
              chmod -R a+w $HOME/project
              pushd $HOME/project

              ${command}
              touch $out
            '';
        projects =
          lib.mapAttrs
            (projectKey: cfg:
              let
                inherit (pkgs.lib.lists) optionals;
                # Apply user provided source-overrides and overrides to
                # `cfg.haskellPackages`.
                hp = cfg.haskellPackages.extend
                  (pkgs.lib.composeExtensions
                    (pkgs.haskell.lib.packageSourceOverrides cfg.source-overrides)
                    cfg.overrides);
                defaultBuildTools = hp: with hp; {
                  inherit
                    cabal-install
                    haskell-language-server
                    ghcid
                    hlint;
                };
                buildTools = lib.attrValues (defaultBuildTools hp // cfg.buildTools hp);
                package' = hp.callCabal2nixWithOptions cfg.name cfg.root "" { };
                package = cfg.modifier package';
                devShell = (hp.extend (self: super: {
                  "${cfg.name}" = package';
                })).shellFor {
                  packages = p: [
                    (cfg.modifier p."${cfg.name}")
                  ];
                  withHoogle = true;
                  buildInputs = buildTools;
                };
                devShellCheck = name: command:
                  runCommandInSimulatedShell devShell cfg.root "${projectKey}-${name}-check" { } command;
              in
              rec {
                inherit package devShell;
                app = { type = "app"; program = pkgs.lib.getExe package; };
                checks = lib.filterAttrs (_: v: v != null)
                  {
                    "${projectKey}-hls" =
                      if cfg.hlsCheck.enable then
                        devShellCheck "hls" "haskell-language-server"
                      else null;
                    "${projectKey}-hlint" =
                      if cfg.hlintCheck.enable then
                        devShellCheck "hlint" ''
                          hlint ${lib.concatStringsSep " " cfg.hlintCheck.dirs}
                        ''
                      else null;
                  };
              }
            )
            config.haskellProjects;
      in
      {
        packages =
          lib.mapAttrs
            (_: project: project.package)
            projects;
        apps =
          lib.mapAttrs
            (_: project: project.app)
            projects;
        checks =
          lib.mkMerge
            (lib.mapAttrsToList
              (_: project: project.checks)
              projects);
        devShells =
          lib.mapAttrs
            (_: project: project.devShell)
            projects;
      };
  };
}
