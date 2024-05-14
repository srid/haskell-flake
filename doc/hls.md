---
order: -8
---

# haskell-language-server

haskell-flake enables [haskell-language-server](https://github.com/haskell/haskell-language-server) and [a few other tools by default](https://github.com/srid/haskell-flake/blob/988a78590c158c5fa0b4893de793c9c783b9d7e9/nix/modules/project/defaults.nix#L23-L29).
{#disable}
## Disabling haskell-language-server

> [!note]
> Only applicable if `haskellProjects.<proj-name>.defaults.enable = true;`

You can set your own `devShell.tools` defaults, that does not include `haskell-language-server`, as follows:

```nix
{
  haskellProjects.<proj-name> = {
    defaults.devShell.tools = hp: with hp; {
      inherit
        cabal-install
        ghcid;
    };
  };
}
```

{#disable-plugins}
## Disabling plugins

>[!warning] TODO
> See here for current status: <https://github.com/srid/haskell-flake/issues/245>
