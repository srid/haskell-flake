
# Default options

haskell-flake provides sensible defaults for various options. See [defaults.nix].

[defaults.nix]: https://github.com/srid/haskell-flake/blob/master/nix/modules/project/defaults.nix

{#override}
## Overriding defaults

{#packages}
### Overriding default local packages

This example shows how to specify [[local]] manually.

```nix
{
  haskellProjects.default = {
    # Specify local packages manually
    defaults.packages = {
      foo.source = ./foo;
    };
  };
}
```
