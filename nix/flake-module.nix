# A flake-parts module for Haskell cabal projects.
{ self, lib, flake-parts-lib, withSystem, ... }:

let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    mkOption
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
              drv = mkOption {
                type = types.package;
                readOnly = true;
                description = ''
                  The `hlsCheck` derivation generated for this project.
                '';
              };
            };
          };
          packageSubmodule = with types; submodule {
            options = {
              root = mkOption {
                type = path;
                description = ''
                  The directory path under which the Haskell package's `.cabal`
                  file or `package.yaml` resides.
                '';
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
              extraLibraries = mkOption {
                type = functionTo (types.attrsOf (types.nullOr types.package));
                description = ''
                  Extra Haskell libraries available in the shell's environment.
                  These can be used in the shell's `runghc` and `ghci` for instance.

                  The argument is the Haskell package set.

                  The return type is an attribute set for overridability and syntax, as only the values are used.
                '';
                default = hp: { };
                defaultText = lib.literalExpression "hp: { }";
                example = lib.literalExpression "hp: { inherit (hp) releaser; }";
              };
              hlsCheck = mkOption {
                default = { };
                type = hlsCheckSubmodule;
                description = ''
                  A [check](flake-parts.html#opt-perSystem.checks) to make sure that your IDE will work.
                '';
              };
              mkShellArgs = mkOption {
                type = types.attrsOf types.raw;
                description = ''
                  Extra arguments to pass to `pkgs.mkShell`.
                '';
                default = { };
                example = ''
                  {
                    shellHook = \'\'
                      # Re-generate .cabal files so HLS will work (per hie.yaml)
                      ''${pkgs.findutils}/bin/find -name package.yaml -exec hpack {} \;
                    \'\';
                  };
                '';
              };
            };
          };
          outputsSubmodule = types.submodule {
            options = {
              finalOverlay = mkOption {
                type = types.raw;
                readOnly = true;
                internal = true;
              };
              finalPackages = mkOption {
                # This must be raw because the Haskell package set also contains functions.
                type = types.attrsOf types.raw;
                readOnly = true;
                description = ''
                  The final Haskell package set including local packages and any
                  overrides, on top of `basePackages`.
                '';
              };
              packages = mkOption {
                type = types.attrsOf packageInfoSubmodule;
                readOnly = true;
                description = ''
                  Package information for all local packages. Contains the following keys:

                  - `package`: The Haskell package derivation
                  - `executables`: Attrset of executables found in the .cabal file
                '';
              };
              apps = mkOption {
                type = types.attrsOf appType;
                readOnly = true;
                description = ''
                  All the `executables` from `packages` option merged.
                '';
              };
              devShell = mkOption {
                type = types.package;
                readOnly = true;
                description = ''
                  The development shell derivation generated for this project.
                '';
              };
              checks = mkOption {
                type = types.lazyAttrsOf types.package;
                readOnly = true;
                description = ''
                  The flake checks generated for this project.
                '';
              };

            };
          };
          derivationType = lib.types.package // {
            check = lib.isDerivation;
          };

          getExe = x:
            "${lib.getBin x}/bin/${x.meta.mainProgram or (throw ''Package ${x.name or ""} does not have meta.mainProgram set, so I don't know how to find the main executable. You can set meta.mainProgram, or pass the full path to executable, e.g. program = "''${pkg}/bin/foo"'')}";
          programType = lib.types.coercedTo derivationType getExe lib.types.str;
          appType = lib.types.submodule {
            options = {
              type = mkOption {
                type = lib.types.enum [ "app" ];
                default = "app";
                description = ''
                  A type tag for `apps` consumers.
                '';
              };
              program = mkOption {
                type = programType;
                description = ''
                  A path to an executable or a derivation with `meta.mainProgram`.
                '';
              };
            };
          };
          packageInfoSubmodule = types.submoduleWith {
            modules = [
              ({ config, ... }: {
                options = {
                  package = mkOption {
                    type = types.package;
                    description = ''
                      Package derivation.
                    '';
                  };
                  exes = mkOption {
                    type = types.attrsOf appType;
                    description = ''
                      Attrset of executables from `.cabal` file.  
                    '';
                  };
                };
              })
            ];
          };
          projectSubmodule = types.submoduleWith {
            specialArgs = { inherit pkgs self; };
            modules = [
              ./haskell-project.nix
              ({ config, ... }: {
                options = {
                  projectRoot = mkOption {
                    type = types.path;
                    description = ''
                      Path to the root of the project directory.

                      Chaning this affects certain functionality, like where to
                      look for the 'cabal.project' file.
                    '';
                    default = self;
                    defaultText = "Top-level directory of the flake";
                  };
                  basePackages = mkOption {
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
                    type = types.attrsOf (types.oneOf [ types.path types.str ]);
                    description = ''
                      Source overrides for Haskell packages

                      You can either assign a path to the source, or Hackage
                      version string.
                    '';
                    default = { };
                  };
                  overrides = mkOption {
                    type = import ./haskell-overlay-type.nix { inherit lib; };
                    description = ''
                      Cabal package overrides for this Haskell project
                
                      For handy functions, see 
                      <https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix>

                      **WARNING**: When using `imports`, multiple overlays
                      will be merged using `lib.composeManyExtensions`.
                      However the order the overlays are applied can be
                      arbitrary (albeit deterministic, based on module system
                      implementation).  Thus, the use of `overrides` via
                      `imports` is not officiallly supported. If you'd like
                      to see proper support, add your thumbs up to
                      <https://github.com/NixOS/nixpkgs/issues/215486>.
                    '';
                    default = self: super: { };
                    defaultText = lib.literalExpression "self: super: { }";
                  };
                  packages = mkOption {
                    type = types.lazyAttrsOf packageSubmodule;
                    description = ''
                      Set of local packages in the project repository.

                      If you have a `cabal.project` file (under `projectRoot`),
                      those packages are automatically discovered. Otherwise, a
                      top-level .cabal or package.yaml file is used to discover
                      the single local project.

                      haskell-flake currently supports a limited range of syntax
                      for `cabal.project`. Specifically it requires an explicit
                      list of package directories under the "packages" option.
                    '';
                    default =
                      let
                        find-haskell-packages = import ./find-haskell-packages {
                          inherit pkgs lib;
                          throwError = msg: builtins.throw ''
                            haskell-flake: A default value for `packages` cannot be auto-determined:

                              ${msg}

                            Please specify the `packages` option manually or change your project configuration.
                          '';
                        };
                      in
                      lib.mapAttrs
                        (_: path: { root = path; })
                        (find-haskell-packages config.projectRoot).packagesPath;
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
                    type = outputsSubmodule;
                    description = ''
                      The flake outputs generated for this project.

                      This is an internal option, not meant to be set by the user.
                    '';
                  };
                  autoWire =
                    let
                      outputTypes = [ "packages" "checks" "apps" "devShells" ];
                    in
                    mkOption {
                      type = types.listOf (types.enum outputTypes);
                      description = ''
                        List of flake output types to autowire.

                        Using an empty list will disable autowiring entirely,
                        enabling you to manually wire them using
                        `config.haskellProjects.<name>.outputs`.
                      '';
                      default = outputTypes;
                    };
                };
              })
            ];
          };
        in
        {
          options = {
            haskellProjects = mkOption {
              description = "Haskell projects";
              type = types.attrsOf projectSubmodule;
            };
          };

          config =
            let
              # Like mapAttrs, but merges the values (also attrsets) of the resulting attrset.
              mergeMapAttrs = f: attrs: lib.mkMerge (lib.mapAttrsToList f attrs);
              mapKeys = f: attrs: lib.mapAttrs' (n: v: { name = f n; value = v; }) attrs;

              contains = k: vs: lib.any (x: x == k) vs;

              # Prefix value with the project name (unless
              # project is named `default`)
              dropDefaultPrefix = projectName: value:
                if projectName == "default"
                then value
                else "${projectName}-${value}";
            in
            {
              packages =
                mergeMapAttrs
                  (name: project:
                    let
                      projectPackages =
                        lib.mapAttrs
                          (_: packageInfo: packageInfo.package)
                          (mapKeys (dropDefaultPrefix name) project.outputs.packages);
                    in
                    lib.optionalAttrs (contains "packages" project.autoWire) projectPackages)
                  config.haskellProjects;
              devShells =
                mergeMapAttrs
                  (name: project:
                    lib.optionalAttrs (contains "devShells" project.autoWire && project.devShell.enable) {
                      "${name}" = project.outputs.devShell;
                    })
                  config.haskellProjects;
              checks =
                mergeMapAttrs
                  (name: project:
                    lib.optionalAttrs (contains "checks" project.autoWire) project.outputs.checks
                  )
                  config.haskellProjects;
              apps =
                mergeMapAttrs
                  (name: project:
                    lib.optionalAttrs (contains "apps" project.autoWire) (mapKeys (dropDefaultPrefix name) project.outputs.apps)
                  )
                  config.haskellProjects;
            };
        });

    flake = mkOption {
      type = types.submoduleWith {
        specialArgs = { inherit withSystem; };
        modules = [
          ./default-project-modules.nix
          {
            options = {
              haskellFlakeProjectModules = mkOption {
                type = types.lazyAttrsOf types.deferredModule;
                description = ''
                  A lazy attrset of `haskellProjects.<name>` modules that can be
                  imported in other flakes.
                '';
                defaultText = ''
                  Package and dependency information for this project exposed for reuse
                  in another flake, when using this project as a Haskell dependency.

                  Typically the consumer of this flake will want to use one of the
                  following modules:

                    - output: provides both local package and dependency overrides.
                    - local: provides only local package overrides (ignores dependency
                      overrides in this flake)

                  These default modules are always available.
                '';
                default = { }; # Set in config (see ./default-project-modules.nix)
              };
            };
          }
        ];
      };

    };
  };
}
