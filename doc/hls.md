---
order: -8
---

# IDE configuration (HLS)

By default, #[[devshell]] of haskell-flake projects includes [haskell-language-server](https://github.com/haskell/haskell-language-server) and [a few other tools by default](https://github.com/srid/haskell-flake/blob/988a78590c158c5fa0b4893de793c9c783b9d7e9/nix/modules/project/defaults.nix#L23-L29).
{#disable}
## Disabling `haskell-language-server`

> [!tip] Default options
> Alternatively, disabling the [[defaults|default options]] (i.e., `haskellProjects.<proj-name>.defaults.enable = false;`) automatically removes HLS.

HLS is included as part of the default value of `devShell.tools` options. You can override this default by overriding it, for e.g.:

```nix
{
  haskellProjects.<proj-name> = {
    # NOTE: This is 'defaults.devShell.tools', not 'devShell.tools'
    defaults.devShell.tools = hp: with hp; {
      inherit
        cabal-install
        ghcid;
    };
  };
}
```

Alternatively, you can set it to `null` at a project-level:

```nix
{
  haskellProjects.<proj-name> = {
    # NOTE: This is 'devShell.tools', not 'defaults.devShell.tools'
    devShell.tools = {
      haskell-language-server = null;
    };
  };
}
```

{#disable-plugins}
## Disabling HLS plugins

>[!warning] TODO
> See here for current status: <https://github.com/srid/haskell-flake/issues/245>
