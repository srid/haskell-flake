---
slug: mission-control
---

# Devshell scripts using mission-control

The [mission-control](https://github.com/Platonic-Systems/mission-control) flake-parts module enables creating a set of scripts or commands to run in the Nix dev shell. This makes it possible for the project's user to locate all of the commands they need (to get started) in one place, often replacing the likes of `Makefile` or `bin/` scripts.

## Usage

To use this module, add `mission-control` to `inputs`,

```nix
{
  # Inside inputs
  mission-control.url = "github:Platonic-Systems/mission-control";
}
```

and import its flakeModule:

```nix
{
  # Inside mkFlake
  imports = [
    inputs.mission-control.flakeModule
  ];
}
```

## Add a script

Here we'll show a sample of scripts that are particular useful when developing Haskell projects.

### Docs (Hoogle)

We can add a convenient script to start Hoogle on project dependencies as follows. As a result, typing `, docs` in the dev shell will start Hoogle.

```nix
{
  # Inside perSystem
  mission-control.scripts = {
    docs = {
      description = "Start Hoogle server for project dependencies";
      exec = ''
        echo http://127.0.0.1:8888
        hoogle serve -p 8888 --local
      '';
      category = "Dev Tools";
    };
  };
}
```
The `exec` option can be either a shell script (string) or a Nix package. The `category` option defines the group that this script belongs to, when displayed in the menu.

### Cabal repl

To start a cabal repl from your devShell on running  `, repl`, use:

```nix
{
  # Inside perSystem
  mission-control.scripts = {
    repl = {
      description = "Start the cabal repl";
      exec = ''
        cabal repl "$@"
      '';
      category = "Dev Tools";
    };
  };
}
```

[`"$@"`](https://www.gnu.org/software/bash/manual/html_node/Special-Parameters.html) represents the command-line arguments passed to `, repl`. This allows us to pass custom arguments to `cabal repl`. For example, if you wish to run an executable `foo` from your project in cabal repl, you'd run `, repl exe:foo`. Similarly, to get into the repl for a library `bar` you'd run `, run lib:bar`.

### treefmt

If you use the [[treefmt|treefmt module]] for autoformatting the source tree, you can alias it as `, fmt`:

```nix
{ 
  # Inside perSystem
  mission-control.scripts = {
    fmt = {
      description = "Format the source tree";
      exec = config.treefmt.build.wrapper;
      category = "Dev Tools";
    };
  };
}
```

Note that `exec` in this example is a Nix package.

## Tips

### wrapperName

If you don't wish to run your command using `, <command>` you can change the `,` to be any string of your choice by setting the option `wrapperName`, as follows:
```nix
{
  # Inside perSystem
  mission-control = {
    wrapperName = "s";
  };
}
```

## Upcoming

- [Zsh and bash shell completion](https://github.com/Platonic-Systems/mission-control/issues/4)

## Example

- https://github.com/srid/haskell-template/blob/master/flake.nix

[mission-control]: https://github.com/Platonic-Systems/mission-control