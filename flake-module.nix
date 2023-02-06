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
                  <https://github.com/haskell/haskell-language-server/issues/3128>),
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
              hlintCheck = mkOption {
                default = { };
                type = hlintCheckSubmodule;
                description = ''
                  A [check](flake-parts.html#opt-perSystem.checks) that runs [`hlint`](https://github.com/ndmitchell/hlint).
                '';
              };
            };
          };
          projectSubmodule = types.submodule (args@{ name, config, ... }: {
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
                  The flake outputs for this project.
                '';
              };
            };
            config = {
              outputs =
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
                  projectKey = name;
                  project =
                    let
                      localPackagesOverlay = self: _:
                        let
                          fromSdist = self.buildFromCabalSdist or (builtins.trace "Your version of Nixpkgs does not support hs.buildFromCabalSdist yet." (pkg: pkg));
                          filterSrc = name: src: lib.cleanSourceWith { inherit src name; filter = path: type: true; };
                        in
                        lib.mapAttrs
                          (name: value:
                            let
                              # callCabal2nix does not need a filtered source. It will
                              # only pick out the cabal and/or hpack file.
                              pkgProto = self.callCabal2nix name value.root { };
                              pkgFiltered = pkgs.haskell.lib.overrideSrc pkgProto {
                                src = filterSrc name value.root;
                              };
                            in
                            fromSdist pkgFiltered)
                          config.packages;
                      finalOverlay =
                        pkgs.lib.composeManyExtensions
                          [
                            # The order here matters.
                            #
                            # User's overrides (cfg.overrides) is applied **last** so
                            # as to give them maximum control over the final package
                            # set used.
                            localPackagesOverlay
                            (pkgs.haskell.lib.packageSourceOverrides config.source-overrides)
                            config.overrides
                          ];
                      finalPackages = config.haskellPackages.extend finalOverlay;

                      defaultBuildTools = hp: with hp; {
                        inherit
                          cabal-install
                          haskell-language-server
                          ghcid
                          hlint;
                      };
                      nativeBuildInputs = lib.attrValues (defaultBuildTools finalPackages // config.devShell.tools finalPackages);
                      devShell = finalPackages.shellFor {
                        inherit nativeBuildInputs;
                        packages = p:
                          map
                            (name: p."${name}")
                            (lib.attrNames config.packages);
                        withHoogle = true;
                      };
                      devShellCheck = name: command:
                        runCommandInSimulatedShell devShell self "${projectKey}-${name}-check" { } command;
                    in
                    {
                      packages =
                        lib.mapAttrs
                          (name: _: finalPackages."${name}")
                          config.packages;
                    } // lib.optionalAttrs config.devShell.enable {
                      inherit devShell;
                      checks = lib.filterAttrs (_: v: v != null)
                        {
                          "${projectKey}-hls" =
                            if config.devShell.hlsCheck.enable then
                              devShellCheck "hls" "haskell-language-server"
                            else null;
                          "${projectKey}-hlint" =
                            if config.devShell.hlintCheck.enable then
                              devShellCheck "hlint" ''
                                hlint ${lib.concatStringsSep " " config.devShell.hlintCheck.dirs}
                              ''
                            else null;
                        };
                    };
                in
                {
                  packages = with lib;
                    mapAttrs'
                      (packageName: package: {
                        name =
                          # Prefix package names with the project name (unless
                          # project is named `default`)
                          if projectKey == "default"
                          then packageName
                          else "${projectName}-${packageName}";
                        value = package;
                      })
                      project.packages;
                  checks = project.checks;
                  devShells.${projectKey} = project.devShell;
                };
            };
          });
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
        flatAttrMap = f: attrs: lib.mkMerge (builtins.map f (lib.attrValues attrs));
      in
      {
        packages =
          flatAttrMap (haskellProject: haskellProject.outputs.packages) config.haskellProjects;
        devShells =
          flatAttrMap (haskellProject: haskellProject.outputs.devShells) config.haskellProjects;
        checks =
          flatAttrMap (haskellProject: haskellProject.outputs.checks) config.haskellProjects;
      };

  };
}
