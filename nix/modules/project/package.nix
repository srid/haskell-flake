# haskellProjects.<name>.packages.<name> module.
{ project, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;
  # TODO: DRY
  isPathUnderNixStore = path: builtins.hasContext (builtins.toString path);
in
{ name, config, ... }: {
  options = {
    source = mkOption {
      type = import ../../types/haskell-source-type.nix { inherit lib; };
      description = ''
        Source refers to a Haskell package defined by one of the following:

        - Path containing the Haskell package's `.cabal` file.
        - Hackage version string
      '';
    };

    cabal.executables = mkOption {
      type = types.nullOr (types.listOf types.string);
      description = ''
        List of executable names found in the cabal file of the package.
        
        The value is null if 'source' option is Hackage version.
      '';
      default =
        let
          haskell-parsers = import ../../haskell-parsers {
            inherit pkgs lib;
            throwError = msg: project.config.log.throwError ''
              Unable to determine executable names for package ${name}:

                ${msg}
            '';
          };
        in
        if isPathUnderNixStore config.source
        then haskell-parsers.getCabalExecutables config.source
        else null; # cfg.source is Hackage version; nothing to do.
    };

    local = mkOption {
      type = types.bool;
      description = ''
        Whether this package is local to the current `projectRoot`.
      '';
      internal = true;
      readOnly = true;
      # We use 'apply' rather than 'default' to make this evaluation lazy at
      # call site (which could be different projectRoot)
      apply = _:
        config.source != null &&
        isPathUnderNixStore config.source &&
        lib.strings.hasPrefix "${project.config.projectRoot}" "${config.source}";
      defaultText = ''
        Computed automatically if package 'source' is under 'projectRoot'.
      '';
    };
  };
}
