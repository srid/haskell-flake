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
                  https://github.com/haskell/haskell-language-server/issues/3128),
                  therefore sandboxing must be disabled when evaluating this
                  check.
                '';
                default = false;
              };

            };
          };
          hlintCheckSubmodule = types.submodule {
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
          packageSubmodule = with types; submodule {
            options = {
              root = mkOption {
                type = path;
                description = "Path to Haskell package where the .cabal file lives";
              };
            };
          };
          projectSubmodule = types.submodule {
            options = {
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
                
                  For handy functions, see https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix
                '';
                default = self: super: { };
              };
              buildTools = mkOption {
                type = functionTo (types.attrsOf (types.nullOr types.package));
                description = ''Build tools for your Haskell package (available only in nix shell).'';
                default = hp: { };
                defaultText = ''Build tools useful for Haskell development are included by default.'';
              };
              hlsCheck = mkOption {
                default = { };
                type = hlsCheckSubmodule;
              };
              hlintCheck = mkOption {
                default = { };
                type = hlintCheckSubmodule;
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
              };
            };
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
                localPackagesOverlay = self: _:
                  lib.mapAttrs
                    (name: value: self.callCabal2nix name value.root { })
                    cfg.packages;
                finalOverlay =
                  pkgs.lib.composeManyExtensions 
                    [ # The order here matters.
                      #
                      # User's overrides (cfg.overrides) is applied **last** so
                      # as to give them maximum control over the final package
                      # set used.
                      cfg.overrides
                      (pkgs.haskell.lib.packageSourceOverrides cfg.source-overrides) 
                      localPackagesOverlay
                    ];
                finalPackages = cfg.haskellPackages.extend finalOverlay;

                defaultBuildTools = hp: with hp; {
                  inherit
                    cabal-install
                    haskell-language-server
                    ghcid
                    hlint;
                };
                buildTools = lib.attrValues (defaultBuildTools finalPackages // cfg.buildTools finalPackages);
                devShell = finalPackages.shellFor {
                  packages = p:
                    map
                      (name: p."${name}")
                      (lib.attrNames cfg.packages);
                  withHoogle = true;
                  nativeBuildInputs = buildTools;
                };
                devShellCheck = name: command:
                  runCommandInSimulatedShell devShell self "${projectKey}-${name}-check" { } command;
              in
              rec {
                inherit devShell;
                packages =
                  lib.mapAttrs
                    (name: _: finalPackages."${name}")
                    cfg.packages;
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
        packages = with lib;
          mkMerge
            (
              mapAttrsToList
                (projectName: project:
                  mapAttrs'
                    (packageName: package: {
                      name =
                        # Prefix package names with the project name (unless
                        # project is named `default`)
                        if projectName == "default"
                        then packageName
                        else "${projectName}-${packageName}";
                      value = package;
                    })
                    project.packages
                )
                projects
            );
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
