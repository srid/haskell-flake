---
slug: /haskell-flake/debugging
---

# Debugging logs

:::warning
This feature is available only in Nix versions 2.10 or later.
:::

Passing `--trace-verbose` to Nix commands causes haskell-flake to print verbose logging of its activity. To enable it:

:::tip[Timestamps in logs]
`moreutils` provides the `ts` command that you can pipe your nix command output to in order to get timestamps in the logs.
:::

The below is a sample output when building [haskell-multi-nix](https://github.com/srid/haskell-multi-nix/tree/debug) with `--trace-verbose`:

```
$ nix --no-eval-cache build -L --trace-verbose github:srid/haskell-multi-nix 2>&1 | ts '[%H:%M:%S]'
[22:45:38] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: default.findPackagesInCabalProject = {"bar":"/nix/store/5zvwxw2n801bbjcz3685dp20y8afjmld-source/./bar","foo":"/nix/store/5zvwxw2n801bbjcz3685dp20y8afjmld-source/./foo"}
[22:45:38] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: defaults.packages = {"bar":{"imports":[{"_file":"/nix/store/sv90dpz2fgn93kvzc14szqn77wvjssv0-source/nix/modules/project/defaults.nix, via option perSystem.aarch64-darwin.haskellProjects.default.defaults.packages.bar","imports":[{"source":"/nix/store/5zvwxw2n801bbjcz3685dp20y8afjmld-source/./bar"}]}]},"foo":{"imports":[{"_file":"/nix/store/sv90dpz2fgn93kvzc14szqn77wvjssv0-source/nix/modules/project/defaults.nix, via option perSystem.aarch64-darwin.haskellProjects.default.defaults.packages.foo","imports":[{"source":"/nix/store/5zvwxw2n801bbjcz3685dp20y8afjmld-source/./foo"}]}]}}
[22:45:38] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: bar.getCabalExecutables = bar
[22:45:38] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: foo.getCabalExecutables = 
[22:45:38] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: default.packages:apply {"bar":{"cabal":{"executables":["bar"]},"local":{"toCurrentProject":true,"toDefinedProject":true},"source":"/nix/store/5zvwxw2n801bbjcz3685dp20y8afjmld-source/./bar"},"foo":{"cabal":{"executables":[]},"local":{"toCurrentProject":true,"toDefinedProject":true},"source":"/nix/store/5zvwxw2n801bbjcz3685dp20y8afjmld-source/./foo"}}
[22:45:40] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: settings.bar {"haddock":false,"libraryProfiling":false}
[22:45:40] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: bar.callCabal2nix /nix/store/5zvwxw2n801bbjcz3685dp20y8afjmld-source/./bar
[22:45:40] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: bar.mkNewStorePath /nix/store/hr0a6v8wwwvw323clv9x28zknd5fqz84-source-bar
[22:45:41] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: bar.cabal2nixDeriver /nix/store/pxcqizj7mvmwflx7hxlq7ll5bdmcis2a-cabal2nix-bar
[22:45:41] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: settings.foo {"haddock":false,"libraryProfiling":false}
[22:45:41] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: foo.callCabal2nix /nix/store/5zvwxw2n801bbjcz3685dp20y8afjmld-source/./foo
[22:45:41] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: foo.mkNewStorePath /nix/store/bpybsny4gd5jnw0lvk5khpq7md6nwg5f-source-foo
[22:45:41] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: foo.cabal2nixDeriver /nix/store/i36x01zcdpm7c3m3fjjq1qa4slv61jpw-cabal2nix-foo
[22:45:41] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: foo.fromSdist /nix/store/qrsy0bm4khcs1hxy0rhb6m3g2bvi15sm-foo-0.1.0.0
[22:45:41] trace: DEBUG[haskell-flake] [haskell-multi-nix#haskellProjects.default]: bar.fromSdist /nix/store/anyx51rm5gjdclafcz5is7jpqgfq2i4w-bar-0.1.0.0
```

## See also

- Read more about [the `traceVerbose` function](https://nixos.asia/en/traceVerbose) which haskell-flake uses to produce the above logs.