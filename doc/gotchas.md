# Gotchas

{#libssh2}
## Overriding `libssh2` Haskell library

Overriding the package with `packages.libssh2.source = "0.2.0.9"` results in infinite recursion.

Possibly having to do with `cabal2nix` not understanding that [`libssh2` in `pkgconfig-depends` of `libssh2.cabal`](https://github.com/portnov/libssh2-hs/blob/bf7cbe643c7f4fb4fad3963705feb8351471eb01/libssh2/libssh2.cabal#L70)
is not self-referential.

Use the following [[settings]] configuration to override `libssh2`:

```nix
# In `haskellProjects.default`
{
  settings = {
    libssh2 = {
      broken = false;
      custom = [ (p: p.overrideAttrs (oa: rec {
        version = "0.2.0.9";
        src = pkgs.fetchzip {
          url = "mirror://hackage/${oa.pname}-${version}/${oa.pname}-${version}.tar.gz";
          sha256 = "sha256-/zzj11iOxkpEsKVwB4+IF8dNZwEuwUlgw+cZYguN8QI=";
        };
      })) ];
    };
  };
}
```

