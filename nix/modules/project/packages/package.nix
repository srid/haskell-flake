# haskellProjects.<name>.packages.<name> module.
{ project, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;

  # Whether the 'path' is local to `project.config.projectRoot`
  localToProject = path:
    path != null &&
    lib.types.path.check path &&
    lib.strings.hasPrefix "${project.config.projectRoot}" "${path}";
in
{ name, config, ... }: {
  options = {
    source = mkOption {
      type = with types; either path str;
      description = ''
        Source refers to a Haskell package defined by one of the following:

        - Path containing the Haskell package's `.cabal` file.
        - Hackage version string
      '';
    };

    cabal2NixFile = lib.mkOption {
      type = lib.types.str;
      description = ''
        The Nix file which contains cached (pre-generated) `cabal2nix` expressions.

        By default, it refers to `cabal.nix` file.
      '';
      default = "cabal.nix";
    };

    cabal.executables = mkOption {
      type = types.nullOr (types.listOf types.str);
      description = ''
        List of executable names found in the cabal file of the package.
        
        The value is null if 'source' option is Hackage version.
      '';
      default =
        let
          haskell-parsers = import ../../../haskell-parsers {
            inherit pkgs lib;
            throwError = msg: project.config.log.throwError ''
              Unable to determine executable names for package ${name}:

                ${msg}
            '';
          };
        in
        if lib.types.path.check config.source
        then
          lib.pipe config.source [
            haskell-parsers.getCabalExecutables
            (x: project.config.log.traceDebug "${name}.getCabalExecutables = ${builtins.toString x}" x)
          ]
        else null; # cfg.source is Hackage version; nothing to do.
    };

    local.toCurrentProject = mkOption {
      type = types.bool;
      description = ''
        Whether this package is local to the project that is importing it.
      '';
      internal = true;
      readOnly = true;
      # We use 'apply' rather than 'default' to make this evaluation lazy at
      # call site (which could be different projectRoot)
      apply = _:
        localToProject config.source;
      defaultText = ''
        Computed automatically if package 'source' is under 'projectRoot' of the
        importing project.
      '';
    };

    local.toDefinedProject = mkOption {
      type = types.bool;
      description = ''
        Whether this package is local to the project it is defined in.
      '';
      internal = true;
      default =
        localToProject config.source;
      defaultText = ''
        Computed automatically if package 'source' is under 'projectRoot' of the
        defining project.
      '';
    };
  };
}
