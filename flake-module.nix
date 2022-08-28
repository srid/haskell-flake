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
                default = "";
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
              enableHLSCheck = mkOption {
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
              # Copy project root to a mutable area
              # We expect "command" to mutate it.
              export HOME=$TMP
              cp -R ${projectRoot} $HOME/project
              chmod -R a+w $HOME/project
              pushd $HOME/project

              ${command}
            '';
        projects =
          lib.mapAttrs
            (projectKey: cfg:
              let
                inherit (pkgs.lib.lists) optionals;
                hp = cfg.haskellPackages;
                defaultBuildTools = with hp; {
                  inherit
                    cabal-install
                    haskell-language-server
                    ghcid
                    hlint;
                };
                buildTools' = defaultBuildTools // cfg.buildTools hp;
                buildTools = lib.attrValues buildTools';
                mkProject = { returnShellEnv ? false, withHoogle ? false }:
                  hp.developPackage {
                    inherit returnShellEnv withHoogle;
                    inherit (cfg) root name source-overrides overrides;
                    modifier = drv:
                      cfg.modifier (pkgs.haskell.lib.overrideCabal drv (oa: {
                        buildTools = (oa.buildTools or [ ]) ++ optionals returnShellEnv buildTools;
                      }));
                  };
              in
              rec {
                package = mkProject { };
                app = { type = "app"; program = pkgs.lib.getExe package; };
                devShell = mkProject { returnShellEnv = true; withHoogle = true; };
                checks =
                  lib.optionalAttrs cfg.enableHLSCheck {
                    "${projectKey}-hls" =
                      runCommandInSimulatedShell
                        devShell
                        cfg.root "${projectKey}-hls-check"
                        { }
                        ''
                          haskell-language-server > $out
                        '';
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
