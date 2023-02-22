# Definition of the `haskellProjects.${name}` submodule's `config`
{ name, self, config, lib, pkgs, ... }:
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
      inherit (config) finalPackages;

      projectKey = name;

      localPackagesOverlay = self: _:
        let
          fromSdist = self.buildFromCabalSdist or (builtins.trace "Your version of Nixpkgs does not support hs.buildFromCabalSdist yet." (pkg: pkg));
        in
        lib.mapAttrs
          (name: value:
            fromSdist (self.callCabal2nix name value.root { })
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
      devShell = finalPackages.shellFor {
        inherit nativeBuildInputs;
        packages = p:
          map
            (name: p."${name}")
            (lib.attrNames config.packages);
        withHoogle = true;
      };
    in
    {
      finalPackages = config.basePackages.extend config.finalOverlay;

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

      outputs = {
        packages =
          let
            mapKeys = f: attrs: lib.mapAttrs' (n: v: { name = f n; value = v; }) attrs;
            # Prefix package names with the project name (unless
            # project is named `default`)
            dropDefaultPrefix = packageName:
              if projectKey == "default"
              then packageName
              else "${projectKey}-${packageName}";
          in
          mapKeys dropDefaultPrefix
            (lib.mapAttrs
              (name: _: finalPackages."${name}")
              config.packages);

        devShells."${projectKey}" = devShell;

        checks = lib.optionalAttrs config.devShell.hlsCheck.enable {
          "${projectKey}-hls" =
            runCommandInSimulatedShell
              devShell
              self "${projectKey}-hls-check"
              { } "haskell-language-server";
        };
      };
    };
}
