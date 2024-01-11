---
slug: /haskell-flake/debugging
---

# Debugging logs

Enabling the `debug` option causes haskell-flake to print verbose logging of its activity. To enable it:

```nix
haskellProjects.default = {
  debug = true;  # Turn on verbose logging
  projectRoot = ./.;
  ...
}
```

>[!tip] Timestamps in logs
> `moreutils` provides the `ts` command that you can pipe your nix command output to in order to get timestamps in the logs.

With debug option enabled, you can execute your `nix` commands piped through `ts` to get timestamps in the debug logs. The below is a sample output when building [haskell-multi-nix](https://github.com/srid/haskell-multi-nix/tree/debug):

```
$ nix build github:srid/haskell-multi-nix/debug#bar 2>&1 | ts '[%Y-%m-%d %H:%M:%S]'
[2024-01-11 15:33:32] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: default.findPackagesInCabalProject = {"bar":"/nix/store/k0ad89r6pa70rly68ibff1jkw59bljgh-source/./bar","foo":"/nix/store/k0ad89r6pa70rly68ibff1jkw59bljgh-source/./foo"}
[2024-01-11 15:33:32] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: defaults.packages = {"bar":{"imports":[{"_file":"/nix/store/n2nb5achv6p0bv3nvqw731mfr907d8ny-source/nix/modules/project/defaults.nix, via option perSystem.aarch64-darwin.haskellProjects.default.defaults.packages.bar","imports":[{"source":"/nix/store/k0ad89r6pa70rly68ibff1jkw59bljgh-source/./bar"}]}]},"foo":{"imports":[{"_file":"/nix/store/n2nb5achv6p0bv3nvqw731mfr907d8ny-source/nix/modules/project/defaults.nix, via option perSystem.aarch64-darwin.haskellProjects.default.defaults.packages.foo","imports":[{"source":"/nix/store/k0ad89r6pa70rly68ibff1jkw59bljgh-source/./foo"}]}]}}
[2024-01-11 15:33:32] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: bar.getCabalExecutables = bar
[2024-01-11 15:33:32] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: foo.getCabalExecutables = 
[2024-01-11 15:33:32] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: default.packages:apply {"bar":{"cabal":{"executables":["bar"]},"local":{"toCurrentProject":true,"toDefinedProject":true},"source":"/nix/store/k0ad89r6pa70rly68ibff1jkw59bljgh-source/./bar"},"foo":{"cabal":{"executables":[]},"local":{"toCurrentProject":true,"toDefinedProject":true},"source":"/nix/store/k0ad89r6pa70rly68ibff1jkw59bljgh-source/./foo"}}
[2024-01-11 15:33:34] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: settings.bar {"haddock":false,"libraryProfiling":false}
[2024-01-11 15:33:34] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: bar.callCabal2nix /nix/store/k0ad89r6pa70rly68ibff1jkw59bljgh-source/./bar
[2024-01-11 15:33:34] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: bar.mkNewStorePath /nix/store/hr0a6v8wwwvw323clv9x28zknd5fqz84-source-bar
[2024-01-11 15:33:35] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: bar.cabal2nixDeriver /nix/store/pxcqizj7mvmwflx7hxlq7ll5bdmcis2a-cabal2nix-bar
[2024-01-11 15:33:35] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: settings.foo {"haddock":false,"libraryProfiling":false}
[2024-01-11 15:33:35] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: foo.callCabal2nix /nix/store/k0ad89r6pa70rly68ibff1jkw59bljgh-source/./foo
[2024-01-11 15:33:35] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: foo.mkNewStorePath /nix/store/bpybsny4gd5jnw0lvk5khpq7md6nwg5f-source-foo
[2024-01-11 15:33:35] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: foo.cabal2nixDeriver /nix/store/i36x01zcdpm7c3m3fjjq1qa4slv61jpw-cabal2nix-foo
[2024-01-11 15:33:35] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: foo.fromSdist /nix/store/qrsy0bm4khcs1hxy0rhb6m3g2bvi15sm-foo-0.1.0.0
[2024-01-11 15:33:35] trace: DEBUG[haskell-flake] [k0ad89r6pa70rly68ibff1jkw59bljgh-source#haskellProjects.default]: bar.fromSdist /nix/store/anyx51rm5gjdclafcz5is7jpqgfq2i4w-bar-0.1.0.0
```