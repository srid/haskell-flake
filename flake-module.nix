# A flake-parts module for Haskell cabal projects.
{ self, config, lib, flake-parts-lib, ... }:

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

            };
          };
          packageSubmodule = with types; submodule {
            options = {
              root = mkOption {
                type = path;
                description = "Path to Haskell package where the `.cabal` file lives";
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
              hlsCheck = mkOption {
                default = { };
                type = hlsCheckSubmodule;
                description = ''
                  A [check](flake-parts.html#opt-perSystem.checks) to make sure that your IDE will work.
                '';
              };
            };
          };
          projectSubmodule = types.submoduleWith {
            specialArgs = { inherit pkgs self; };
            modules = [
              ./haskell-project.nix
              {
                options = {
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
                    type = types.attrsOf types.path;
                    description = ''Package overrides given new source path'';
                    default = { };
                  };
                  overrides =
                    let
                      # WARNING: While the order is deterministic, it is not
                      # determined by the user. Thus overlays may be applied in
                      # an unexpected order.
                      # We need: https://github.com/NixOS/nixpkgs/issues/215486
                      haskellOverlayType = types.mkOptionType {
                        name = "haskellOverlay";
                        description = "An Haskell overlay function";
                        descriptionClass = "noun";
                        # NOTE: This check is not exhaustive, as there is no way
                        # to check that the function takes two arguments, and
                        # returns an attrset.
                        check = lib.isFunction;
                        merge = _loc: defs:
                          let
                            logWarning =
                              if builtins.length defs > 1
                              then builtins.trace "WARNING[haskell-flake]: Multiple haskell overlays are applied in arbitrary order." null
                              else null;
                            overlays =
                              map (x: x.value)
                                (builtins.seq
                                  logWarning
                                  defs);
                          in
                          lib.composeManyExtensions overlays;
                      };
                    in
                    mkOption {
                      type = haskellOverlayType;
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
                      Attrset of local packages in the project repository.

                      Autodiscovered by default by looking for `.cabal` files in
                      top-level or sub-directories.
                    '';
                    default =
                      # We look for a single *.cabal in project root. Otherwise,
                      # look for multiple */*.cabal. Otherwise, error out.
                      #
                      # In future, we could just read `cabal.project`. See #76.
                      let
                        toplevel-cabal-paths =
                          lib.concatMapAttrs
                            (f: _:
                              if lib.strings.hasSuffix ".cabal" f
                              then { "${lib.strings.removeSuffix ''.cabal'' f}" = self; }
                              else { }
                            )
                            (builtins.readDir self);
                        subdir-cabal-paths = lib.filesystem.haskellPathsInDir self;
                        errorNoDefault = msg:
                          lib.asserts.assertMsg false '' 
                              A default value for `packages` cannot be auto-detected:

                                ${msg}
                              You must manually specify the `packages` option.
                            '';
                        cabal-paths =
                          if toplevel-cabal-paths != { }
                          then
                            let cabalNames = lib.attrNames toplevel-cabal-paths;
                            in if builtins.length cabalNames > 1
                            then
                              errorNoDefault ''
                                More than one .cabal file found in project root:

                                  - ${lib.concatStringsSep ".cabal\n  - " cabalNames}.cabal
                              ''
                            else
                              toplevel-cabal-paths
                          else if subdir-cabal-paths != { }
                          then
                            subdir-cabal-paths
                          else
                            errorNoDefault "No .cabal file found.";
                      in
                      lib.mapAttrs
                        (_: value: { root = value; })
                        cabal-paths;
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
                    type = types.attrsOf types.raw;
                    description = ''
                      The flake outputs generated for this project.

                      This is an internal option, not meant to be set by the user.
                    '';
                  };

                  # Derived options

                  finalPackages = mkOption {
                    type = types.attrsOf raw;
                    readOnly = true;
                    description = ''
                      The final package set, based on `basePackages` plus
                      the additions and overrides specified in the other options.
                    '';
                  };
                  finalOverlay = mkOption {
                    type = types.raw;
                    readOnly = true;
                    internal = true;
                  };
                };
              }
            ];
          };
        in
        {
          options = {
            haskellProjects = mkOption {
              description = "Haskell projects";
              type = types.attrsOf projectSubmodule;
            };

            haskellFlakeProjectModules = mkOption {
              type = types.lazyAttrsOf types.deferredModule;
              default = { };
              description = ''
                An attrset of `haskellProjects.<name>` modules that can be imported in
                other flakes.
              '';
            };
          };

          config =
            let
              # Like mapAttrs, but merges the values (also attrsets) of the resulting attrset.
              mergeMapAttrs = f: attrs: lib.mkMerge (lib.mapAttrsToList f attrs);
            in
            {
              packages =
                mergeMapAttrs (_: project: project.outputs.packages) config.haskellProjects;
              devShells =
                mergeMapAttrs
                  (_: project:
                    lib.optionalAttrs project.devShell.enable project.outputs.devShells)
                  config.haskellProjects;
              checks =
                mergeMapAttrs
                  (_: project:
                    lib.optionalAttrs project.devShell.enable project.outputs.checks)
                  config.haskellProjects;
            };
        });
  };
}
