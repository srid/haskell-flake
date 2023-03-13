---
slug: direnv
---

# Using direnv to manage dev environments

`direnv`, and [nix-direnv] in particular, is an important piece of tool you can use to both persist nix devshell environments and to share it automatically with text editors and IDEs. It also obviates having to run `nix develop` manually every time you open a new terminal. The moment you `cd` into your project directory, the devshell is automatically activated, thanks to `direnv`. 

## Starship

It is recommended to use [starship](https://starship.rs/) along with nix-direnv, because it gives a visual indication of the current environment. For example, if you are in a `nix develop` shell, your terminal prompt to change to something like this:

```sh
srid on appreciate haskell-template on  master [!] via λ 9.2.6 via ❄️  impure (ghc-shell-for-haskell-template-0.1.0.0-0-env)
❯
```

## Setup 

If you use [home-manager](https://github.com/nix-community/home-manager), both `nix-direnv` and `starship` can be installed using the following configuration:

```nix
programs.direnv = {
  enable = true;
  nix-direnv = {
    enable = true;
  };
};
programs.starship = {
  enable = true;
};
```

### Text Editor configuration

#### VSCode

For VSCode, use [Martin Kühl's direnv extension](https://marketplace.visualstudio.com/items?itemName=mkhl.direnv).

#### Doom Emacs

Doom Emacs has the [`:tools` `direnv` module](https://github.com/doomemacs/doomemacs/tree/master/modules/tools/direnv) to automatically load the devshell environment when you open the project directory.

## `.envrc`

To enable direnv on Flake-based projects, add the following to your `.envrc`:

```text
use flakes
```

Now run `direnv allow` to authorize the current `.envrc` file. You can now `cd` into the project directory in a terminal and the devshell will be automatically activated.

## Reload when .cabal file changes

Since both [[nixpkgs-haskell|nixpkgs]] and [[start|haskell-flake]] use Nix expressions that read the `.cabal` file to get dependency information, you will want the devshell be recreated every time a `.cabal` file changes. This can be achieved using the `nix_direnv_watch_file` function. Modify your `.envrc` to contain:

```text
nix_direnv_watch_file *.cabal
use flake
```

As a result of this whenever you change a `.cabal` file, direnv will reload the environment. If you are using VSCode, you will see a notification that the environment has changed, prompting you to restart it.

[nix-direnv]: https://github.com/nix-community/nix-direnv