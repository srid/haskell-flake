{ pkgs, lib, ... }:
let
  derivationType = lib.types.package // {
    check = lib.isDerivation;
  };

  getExe = x:
    "${lib.getBin x}/bin/${x.meta.mainProgram or (throw ''Package ${x.name or ""} does not have meta.mainProgram set, so I don't know how to find the main executable. You can set meta.mainProgram, or pass the full path to executable, e.g. program = "''${pkg}/bin/foo"'')}";
  programType = lib.types.coercedTo derivationType getExe lib.types.str;
  appType = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lib.types.enum [ "app" ];
        default = "app";
        description = ''
          A type tag for `apps` consumers.
        '';
      };
      program = lib.mkOption {
        type = programType;
        description = ''
          A path to an executable or a derivation with `meta.mainProgram`.
        '';
      };
    };
  };
in
appType
