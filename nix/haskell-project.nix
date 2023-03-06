# Definition of the `haskellProjects.${name}` submodule's `config`
{ name, self, config, lib, pkgs, withSystem, ... }:
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
in
{

  config =
    let
      inherit (config.outputs) finalPackages finalOverlay;

      projectKey = name;

      localPackagesOverlay = self: _:
        let
          fromSdist = self.buildFromCabalSdist or (builtins.trace "Your version of Nixpkgs does not support hs.buildFromCabalSdist yet." (pkg: pkg));
          # If `root` has package.yaml, but no cabal file, generate the cabal
          # file and return the new source tree.
          realiseHpack = name: root:
            let
              contents = lib.attrNames (builtins.readDir root);
              hasCabal = lib.any (lib.strings.hasSuffix ".cabal") contents;
              hasHpack = builtins.elem ("package.yaml") contents;
            in
            if (!hasCabal && hasHpack)
            then
              pkgs.runCommand
                "${name}-hpack"
                { nativeBuildInputs = [ pkgs.hpack ]; }
                ''
                  cp -r ${root} $out
                  chmod u+w $out
                  cd $out
                  hpack
                ''
            else root;
        in
        lib.mapAttrs
          (name: value:
            # NOTE: Even though cabal2nix does run hpack automatically,
            # buildFromCabalSdist does not. So we must run hpack ourselves at
            # the original source level.
            let root = realiseHpack name value.root;
            in fromSdist (self.callCabal2nix name root { })
          )
          config.packages;

      defaultBuildTools = hp: with hp; {
        inherit
          cabal-install
          haskell-language-server
          ghcid
          hlint;
      };
      nativeBuildInputs = lib.attrValues (defaultBuildTools finalPackages // config.devShell.tools finalPackages);
      mkShellArgs = config.devShell.mkShellArgs // {
        nativeBuildInputs = (config.devShell.mkShellArgs.nativeBuildInputs or [ ]) ++ nativeBuildInputs;
      };
      devShell = finalPackages.shellFor (mkShellArgs // {
        packages = p:
          map
            (name: p."${name}")
            (lib.attrNames config.packages);
        withHoogle = true;
      });
    in
    {
      outputs = {
        inherit devShell;

        finalOverlay = lib.composeManyExtensions [
          # The order here matters.
          #
          # User's overrides (cfg.overrides) is applied **last** so
          # as to give them maximum control over the final package
          # set used.
          localPackagesOverlay
          (pkgs.haskell.lib.packageSourceOverrides config.source-overrides)
          config.overrides
        ];

        finalPackages = config.basePackages.extend finalOverlay;

        localPackages = lib.mapAttrs
          (name: _: finalPackages."${name}")
          config.packages;

        hlsCheck = runCommandInSimulatedShell
          devShell
          self "${projectKey}-hls-check"
          { } "haskell-language-server";

        projectModules = rec {
          # The 'output' module provides both local package and dependency
          # overrides.
          output = {
            imports = [ input local ];
          };
          # The 'local' module provides only local package overrides.
          local = { pkgs, lib, ... }: withSystem pkgs.system ({ config, ... }: {
            source-overrides =
              lib.mapAttrs (_: v: v.root)
                config.haskellProjects.default.packages;
          });
          # The 'input' module contains only dependency overrides.
          input = { pkgs, ... }: withSystem pkgs.system ({ config, ... }: {
            inherit (config.haskellProjects.default)
              source-overrides overrides;
          });
        };
      };
    };
}
