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
      inherit (config.outputs) finalPackages finalOverlay;

      projectKey = name;

      localPackagesOverlay = self: _:
        let
          build-haskell-package = import ./build-haskell-package.nix { inherit pkgs lib self; };
        in
        lib.mapAttrs build-haskell-package config.packages;

      # TODO: move this to `parser.nix` and add tests
      parseExecutables = pkg:
        let
          cabalContents = builtins.readFile (lib.concatStringsSep "/" [ pkg.root (builtins.head (lib.filter (lib.strings.hasSuffix ".cabal") (builtins.attrNames (builtins.readDir pkg.root)))) ]);
          regexExecutables = builtins.map (x: builtins.match ''^executable ([a-zA-Z0-9_.-]*)$'' x) (lib.strings.splitString "\n" cabalContents);
          filterExecutables = builtins.map (x: builtins.head x) (builtins.filter (x: x != null) regexExecutables);
        in
        filterExecutables;

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
      exes =
        (name: value:
          builtins.foldl' (x: y: x // y) { }
            (builtins.map
              (x: {
                "${x}" = {
                  type = "app";
                  program = "${finalPackages.${name}}/bin/${x}";
                };
              })
              (parseExecutables value)
            )
        );
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

        packages = lib.mapAttrs
          (name: value: value // { package = finalPackages."${name}"; exes = exes name value; })
          config.packages;

        hlsCheck = runCommandInSimulatedShell
          devShell
          self "${projectKey}-hls-check"
          { } "haskell-language-server";

      };
    };
}
