---
slug: nix
---

# Install Nix

To install Nix, follow the instructions at https://github.com/DeterminateSystems/nix-installer#the-determinate-nix-installer

This installer automatically [enable flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes). If you are on macOS, make sure to use the native (not rosetta) terminal.[^so]

To test your Nix install, run:

```sh
nix run nixpkgs#nix-info -- -m
```

Note: If you are on an ARM-based Mac (like M1), the `system` field of `nix-info`'s output must say `"aarch64-darwin"`. If it instead says `"x86_64-darwin"`, it means that you have incorrectly installed Nix (i.e., under Rosetta).

## See also

- [[nix-rapid]]
- [NixOS](https://nixos.org/), a Linux distro based on the Nix package manager.
- [nix-darwin](https://github.com/LnL7/nix-darwin), replaces homebrew and the like on macOS, using Nix.

[^so]: Use the `sysctl -n sysctl.proc_translated` command to check this. [Ref](https://stackoverflow.com/a/67690510/55246)
