---
slug: /haskell/nixpkgs
---

# Nixifying a Haskell project using nixpkgs

:::{.more}
If you are new to Nix or flakes, read [[nix-rapid]] first.
:::

This tutorial enables you to write a flake using nothing but [nixpkgs] to nixify an existing Haskell project. The tutorial serves a pedagogic purpose; in the real-world scenario, we recommend that you use haskell-flake (see [[start]]).

[nixpkgs] provides two important functions for developing Haskell projects that we'll extensively use here. They are `callCabal2nix` and `shellFor`, and are described below.

:::{.more}
To learn more:
- [Official manual](https://nixos.org/manual/nixpkgs/unstable/#haskell)
:::

## callCabal2nix

[`callCabal2nix`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/make-package-set.nix) produces a derivation for building a Haskell package from source. This source can be any path, including a local directory (eg.: `./.`) or a flake input. We'll use `callCabal2nix` to build a package from source during overriding the Haskell package set using overlays (see below).

## Package sets

[nixpkgs] also provides a Haskell package set (built, in part, from Stackage but also Hackage) for each GHC compiler version. The default compiler's package set is provided in `pkgs.haskellPackages`. In the repl session below, we locate and build the `aeson` package:

```nix
❯ nix repl github:nixos/nixpkgs/nixpkgs-unstable
nix-repl> pkgs = legacyPackages.${builtins.currentSystem}

nix-repl> pkgs.haskellPackages.aeson
«derivation /nix/store/sjaqjjnizd7ybirh94ixs51x4n17m97h-aeson-2.0.3.0.drv»

nix-repl> :b pkgs.haskellPackages.aeson

This derivation produced the following outputs:
  doc -> /nix/store/xjvm45wxqasnd5p2kk9ngcc0jbjhx1pf-aeson-2.0.3.0-doc
  out -> /nix/store/1dc6b11k93a6j9im50m7qj5aaa5p01wh-aeson-2.0.3.0
```

### Overlays

:::{.more}
To learn more:
- [NixOS Wiki on Overlays](https://nixos.wiki/wiki/Overlays)
- [Overlay implementation in fixed-points.nix](https://github.com/NixOS/nixpkgs/blob/master/lib/fixed-points.nix)
:::


Using the overlay system, you can *extend* this package set, to either add new packages or override existing ones. The package set exposes a function called `extend` for this purpose. In the repl session below, we extend the default Haskell package set to override the `shower` package to be built from the Git repo instead:

```nix
nix-repl> :b pkgs.haskellPackages.shower

This derivation produced the following outputs:
  doc -> /nix/store/crzcx007h9j0p7qj35kym2rarkrjp9j1-shower-0.2.0.3-doc
  out -> /nix/store/zga3nhqcifrvd58yx1l9aj4raxhcj2mr-shower-0.2.0.3

nix-repl> myHaskellPackages = pkgs.haskellPackages.extend 
    (self: super: {
       shower = self.callCabal2nix "shower" 
         (pkgs.fetchgit { 
            url = "https://github.com/monadfix/shower.git";
            rev = "2d71ea1"; 
            sha256 = "sha256-vEck97PptccrMX47uFGjoBVSe4sQqNEsclZOYfEMTns="; 
         }) {}; 
    })

nix-repl> :b myHaskellPackages.shower

This derivation produced the following outputs:
  doc -> /nix/store/vkpfbnnzyywcpfj83pxnj3n8dfz4j4iy-shower-0.2.0.3-doc
  out -> /nix/store/55cgwfmayn84ynknhg74bj424q8fz5rl-shower-0.2.0.3
```

Notice how we used `callCabal2nix` to build a new Haskell package from the source (located in the specified Git repository).

## Development shell

A Haskell development environment can be provided in one of the two ways. The native way will use the (language-independent) `mkShell` function (Generic shell). However to get full IDE support, it is best to use the (haskell-specific) `shellFor` function (Haskell shell).

### Haskell shell

:::{.more}
To learn more:
- [Official manual on `shellFor`](https://nixos.org/manual/nixpkgs/unstable/#haskell-shellFor)
:::


Suppose we have a Haskell project called "foo" with `foo.cabal`. You would create the development shell for this project as follows:

```nix
devShells.default = pkgs.haskellPackages.shellFor {
  packages = p: [
    p.foo
  ];
  buildInputs = with pkgs.haskellPackages; [
    ghcid
    cabal-install
    haskell-language-server
  ];
}
```

The `packages` argument to `shellFor` simply indicates that the given packages are available locally in the flake root, and that `cabal` should build them from the local source (rather than using the Nix store derivation for example). The `buildInputs` argument is similar to that of `mkShell` -- it allows you to specify the packages you want to be made available in the development shell.

From inside of `nix develop` shell, launch your pre-configured text editor (for example, VSCode with the [Haskell extension](https://marketplace.visualstudio.com/items?itemName=haskell.haskell) installed). You should have full IDE support.

## Example

The flake for [haskell-multi-nix](https://github.com/srid/haskell-multi-nix) is presented below. This project has two Haskell packages "foo" and "bar".

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs, ... }:
    let
      # TODO: Change this to your current system, or use flake-utils/flake-parts.
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      overlay = self: super: {
        # Local packages in the repository
        foo = self.callCabal2nix "foo" ./foo { };
        bar = self.callCabal2nix "bar" ./bar { };
        # TODO: Put any library dependency overrides here
      };
      # Extend the `pkgs.haskellPackages` attrset using an overlay.
      #
      # Note that we can also extend the package set using more than one
      # overlay. To do that we can either chain the `extend` calls or use
      # the `composeExtensions` (or `composeManyExtensions`) function to
      # merge the overlays.
      haskellPackages' = pkgs.haskellPackages.extend overlay;
    in
    {
      packages.${system} = {
        inherit (haskellPackages') foo bar;
        default = haskellPackages'.bar;
      };
      # This is how we provide a multi-package dev shell in Haskell.
      # By using the `shellFor` function.
      devShells.${system}.default = haskellPackages'.shellFor {
        packages = p: [
          p.foo
          p.bar
        ];
        buildInputs = with haskellPackages'; [
          ghcid
          cabal-install
          haskell-language-server
        ];
      };
    };
}
```

You can confirm that the package builds by running either `nix build .#foo` or `nix build .#bar`, as well as that IDE support is configured correctly by running `nix develop -c haskell-language-server`.

A variation of this flake supporting multiple systems (via use of flake-parts) can be found [here](https://github.com/srid/haskell-multi-nix/blob/nixpkgs/flake.nix).

[nixpkgs]: https://zero-to-nix.com/concepts/nixpkgs