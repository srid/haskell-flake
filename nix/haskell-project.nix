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

  hlib = pkgs.haskell.lib.compose;

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
          makeSrcAutonomous = name: root: pkg: hlib.overrideSrc
            {
              src =
                # Since 'root' may be a subdirectory of a store path
                # (in string form, which means that it isn't automatically
                # copied), the purpose of cleanSourceWith here is to create a
                # new (smaller) store path that is a copy of 'root' but
                # does not contain the unrelated parent source contents.
                lib.cleanSourceWith {
                  name = "source-${name}-${pkg.version}";
                  src = root;
                };
            }
            pkg;
        in
        lib.mapAttrs
          (name: pkgCfg:
            let
              # NOTE: Even though cabal2nix does run hpack automatically,
              # buildFromCabalSdist does not. So we must run hpack ourselves at
              # the original source level.
              root = realiseHpack name pkgCfg.root;
              pkg = self.callCabal2nix name root { };
            in
            lib.pipe pkg
              [
                # Avoid rebuilding because of changes in parent directories
                (makeSrcAutonomous name root)

                # Make sure all files we use are included in the sdist, as a check
                # for release-worthiness.
                fromSdist
              ]
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

        finalOverlay = lib.composeManyExtensions [
          # The order here matters.
          #
          # User's overrides (cfg.overrides) is applied **last** so
          # as to give them maximum control over the final package
          # set used.
          localPackagesOverlay
          (hlib.packageSourceOverrides config.source-overrides)
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

      };
    };
}
