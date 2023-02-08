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
  outputs =
    let
      projectKey = name;

      finalPackages = config.finalPackages;

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

    } // lib.optionalAttrs config.devShell.hlsCheck.enable {

      checks."${projectKey}-hls" =
        runCommandInSimulatedShell
          devShell
          self "${projectKey}-hls-check"
          { } "haskell-language-server";
    };
}
