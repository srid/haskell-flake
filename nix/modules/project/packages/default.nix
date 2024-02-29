# Definition of the `haskellProjects.${name}` submodule's `config`
project@{ name, lib, pkgs, ... }:
let
  inherit (lib)
    types;

  packageSubmodule = import ./package.nix { inherit project lib pkgs; };

  # Merge the list of attrset of modules.
  mergeModuleAttrs =
    lib.zipAttrsWith (k: vs: { imports = vs; });

  tracePackages = k: x:
    project.config.log.traceDebug "${k} ${builtins.toJSON x}" x;

  # Return true of package configuration points to a source path.
  # Return false if it points to Hackage version
  isSource = cfg:
    lib.types.path.check cfg.source;
in
{
  options = {
    packages = lib.mkOption {
      type = types.lazyAttrsOf types.deferredModule;
      default = { };
      apply = packages:
        let
          packages' =
            # Merge user-provided 'packages' with 'defaults.packages'. 
            #
            # Note that the user can override the latter too if they wish.
            mergeModuleAttrs
              [ project.config.defaults.packages packages ];
        in
        tracePackages "${name}.packages:apply" (
          lib.mapAttrs
            (name: v:
              (lib.evalModules {
                modules = [ packageSubmodule v ];
                specialArgs = { inherit name pkgs; };
              }).config
            )
            packages');

      description = ''
        Additional packages to add to `basePackages`.

        Local packages are added automatically (see `config.defaults.packages`):

        You can also override the source for existing packages here.
      '';
    };

    packagesOverlays.before = lib.mkOption {
      type = import ../../../types/haskell-overlay-type.nix { inherit lib; };
      description = ''
        The Haskell overlay computed from `packages` modules.
      '';
      internal = true;
      default = self: _super:
        let
          inherit (project.config) log;
          build-haskell-package = import ../../../build-haskell-package.nix {
            inherit pkgs lib self log;
          };
          getOrMkPackage = name: cfg:
            if isSource cfg
            then
              log.traceDebug "${name}.callCabal2nix ${cfg.source}"
                (build-haskell-package name cfg.source)
            else
              log.traceDebug "${name}.callHackage ${cfg.source}"
                (self.callHackage name cfg.source { });
        in
        lib.mapAttrs getOrMkPackage project.config.packages;
    };

    packagesOverlays.after = lib.mkOption {
      type = import ../../../types/haskell-overlay-type.nix { inherit lib; };
      description = ''
        The Haskell overlay to apply at the very end (after settings overlay)
      '';
      internal = true;
      default = self: super:
        let
          inherit (project.config) log;
          # NOTE: We do not use the optimized version, `buildFromCabalSdist`, because it
          # breaks in some cases. See https://github.com/srid/haskell-flake/pull/220
          fromSdist = pkgs.haskell.lib.buildFromSdist or
            (log.traceWarning "Your nixpkgs does not have hs.buildFromSdist" (pkg: pkg));
          f = name: cfg:
            if isSource cfg
            then
            # Make sure all files we use are included in the sdist, as a check
            # for release-worthiness.
              log.traceDebug "${name}.fromSdist ${super.${name}.outPath} (source = ${cfg.source})"
                fromSdist
                super.${name}
            else
              super.${name};
        in
        #lib.filterAttrs
          #  (_: v: v != null)
        (lib.mapAttrs f project.config.packages);
    };
  };
}
