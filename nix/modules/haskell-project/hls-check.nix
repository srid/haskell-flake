# Definition of the `haskellProjects.${name}` submodule's `config`
{ name, self, config, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;

  # Like pkgs.runCommand but runs inside nix-shell with a mutable project directory.
  #
  # It currenty respects only the nativeBuildInputs (and no shellHook for
  # instance), which seems sufficient for our purposes. We also set $HOME and
  # make the project root mutable, because those are expected when running
  # something in a project shell (it is indeed the case with HLS).
  runCommandInSimulatedShell = devShell: projectRoot: name: attrs: command:
    pkgs.runCommand name (attrs // { inherit (devShell) nativeBuildInputs; })
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
      drv = mkOption {
        type = types.package;
        readOnly = true;
        description = ''
          The `hlsCheck` derivation generated for this project.
        '';
      };
    };
  };


in
{
  options = {

    devShell.hlsCheck = mkOption {
      default = { };
      type = hlsCheckSubmodule;
      description = ''
        A [check](flake-parts.html#opt-perSystem.checks) to make sure that your IDE will work.
      '';
    };
    outputs.checks = mkOption {
      type = types.lazyAttrsOf types.package;
      readOnly = true;
      description = ''
        The flake checks generated for this project.
      '';
    };

  };
  config =
    let
      projectKey = name;

      hlsCheck =
        runCommandInSimulatedShell
          config.outputs.devShell
          self "${projectKey}-hls-check"
          { } "haskell-language-server";
    in
    {
      outputs = {
        checks = lib.filterAttrs (_: v: v != null) {
          "${name}-hls" = if (config.devShell.enable && config.devShell.hlsCheck.enable) then hlsCheck else null;
        };
      };

      devShell.hlsCheck.drv = hlsCheck;
    };
}
