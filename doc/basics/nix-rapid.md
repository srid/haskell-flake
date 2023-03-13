---
slug: nix-rapid
---

# Rapid Introduction to Nix

The goal of this document is to introduce you to Nix as quickly as possible while also preparing the motivated learner to dive deeper into [the whole Nix ecosystem][zero-to-nix]. At the end of this introduction, you will be able to create a flake for building a package and providing a developer environment shell.

## Install

Nix can be installed on Linux and macOS. Follow the instructions on [[nix]]. If you are using [NixOS], it already comes with Nix pre-installed.

## Attrset

:::{.more}
To learn more:
- [Official manual](https://nixos.org/manual/nix/stable/language/values.html#attribute-set)
- [nix.dev on attrsets](https://nix.dev/tutorials/nix-language#attribute-set)
:::

The [Nix programming language][nix-lang] provides a lot of general constructs. But at its most basic use, it makes heavy use of ==nested hash maps==, otherwise called an "attrset". They are equivalent to [`Map Text a`](https://hackage.haskell.org/package/containers-0.6.7/docs/Data-Map-Strict.html#t:Map) in Haskell. The following is a simple example of an attrset:

```nix
{
  foo = {
    bar = 1;
  };
}
```

We have an outer attrset with a single key `foo`, whose value is another attrset with a single key `bar` and a value of `1`.

## repl 

Nix expressions can be readily evaluated in the [Nix repl][nix-repl]. To start the repl, run `nix repl`. 

```sh
$ nix repl
Welcome to Nix 2.12.0. Type :? for help.

nix-repl>
```

You can then evaluate expressions:

```nix
nix-repl> 2+3
5

nix-repl> x = { foo = { bar = 1; }; }

nix-repl> x
{ foo = { ... }; }

nix-repl> x.foo
{ bar = 1; }

nix-repl> x.foo.bar
1

nix-repl>
```

## Flakes

:::{.more}
To learn more:
- [Serokell Blog: Basic flake structure](https://serokell.io/blog/practical-nix-flakes#basic-flake-structure)
- [Enable flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes) (flakes are not enabled by default)
:::

A Nix flake is defined in the `flake.nix` file, which denotes an attrset containing the keys "inputs" and "outputs". *Outputs* can reference *inputs*. Thus, changing an *input* can change the *outputs*. The following is a simple example of a flake:

```nix
{
  inputs = { };

  outputs = inputs: {
    foo = 42;
  };
}
```

This flake has zero `inputs`. `outputs` is a [function][nix-function] that takes the (realised) inputs as an argument and returns the final output attrset. This output attrset, in our example, has a single key `foo` with a value of `42`.

We can use the [`nix flake show`][nix-flake-show] command to see the output structure of a flake:

```sh
$ nix flake show
path:/Users/srid/code/nixplay?lastModified=1675373998&narHash=sha256-ifNiFGU1VV784kVcssn2rXIil%2feHfMLhPfmvaELefwA=
└───foo: unknown
$
```

And we can use [`nix eval`][nix-eval] to evaluate any output. For example,

```sh
$ nix eval .#foo
42
```

### Graph

A flake can refer to other flakes in its inputs. Phrased differently, a flake's outputs can be used as inputs in other flakes. The most common example is the [nixpkgs](https://zero-to-nix.com/concepts/nixpkgs) flake which gets used as an input in most flakes. Intuitively, you may visualize a flake to be a node in a larger graph, with inputs being the incoming arrows and outputs being the outgoing arrows.

### Inputs

:::{.more}
To learn more,
- [URL-like syntax][flake-url] used by the `url` attribute
:::

Let's do something more interesting with our `flake.nix` by adding the nixpkgs input:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs: {
    # Note: If you are macOS, substitute `x86_64-linux` with `aarch64-darwin`
    foo = inputs.nixpkgs.legacyPackages.x86_64-linux.cowsay;
  };
}
```

The nixpkgs flake has an output called `legacyPackages`, which is indexed by the platform (called "system" in Nix-speak), further containing all the packages for that system. We assign that package to our flake output key `foo`. 

:::{.tip}
**Tip**:

You can use [`nix repl`][nix-repl] to explore the outputs of any flake, using TAB completion:

```sh
$ nix repl --extra-experimental-features 'flakes repl-flake' github:nixos/nixpkgs/nixpkgs-unstable
Welcome to Nix 2.12.0. Type :? for help.

Loading installable 'github:nixos/nixpkgs/nixpkgs-unstable#'...
Added 5 variables.
nix-repl> legacyPackages.aarch64-darwin.cowsay
«derivation /nix/store/0s2vdpkpdiljmh8y06xgdw5vg2cqfs0m-cowsay-3.7.0.drv»

nix-repl>
```
:::

### Predefined outputs

Nix commands treat certain outputs as special. These are:

| Output      | Nix command       | Description           |
| ----------- | ----------------- | --------------------- |
| `packages`  | `nix build`       | Derivation output     |
| `devShells` | `nix develop`     | Development shells    |
| `apps`      | `nix run`         | Runnable applications |
| `checks`    | `nix flake check` | Tests and checks      |

All of these predefined outputs are further indexed by the "system" value. 

#### Packages 

:::{.more}
To learn more,
- [`pkgs.stdenv.mkDerivation`](https://nixos.org/manual/nixpkgs/stable/#sec-using-stdenv) can be used to build a custom package from scratch
:::

`packages` is the most often used output. Let us extend our previous `flake.nix` to use it:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs: {
    foo = 42;
    packages.x86_64-linux = {
      cowsay = inputs.nixpkgs.legacyPackages.x86_64-linux.cowsay;
    };
  };
}
```

Here, we are producing an output named `packages` that is an attrset of systems (currently, only `x86_64-linux`) to attrsets of packages. We are definining exactly one package, `cowsay`, for the `x86_64-linux` system. 

```sh
$ nix flake show
path:/Users/srid/code/nixplay?lastModified=1675374260&narHash=sha256-FRven09fX3hutGa8+dagOCSQKVYAsHI6BsnCSEQ7PG8=
├───foo: unknown
└───packages
    └───aarch64-darwin
        └───cowsay: package 'cowsay-3.7.0'
```

Notice that `nix flake show` recognizes the *type* of `packages`. With `foo`, it couldn't (hence type is `unknown`) but with `packages`, it can (hence type is "package").

The `packages` output is recognized by `nix build`.

```sh
$ nix build .#cowsay
```

The [`nix build`][nix-build] command takes as argument a value of the form `<flake-url>#<package-name>`. By default, `.` (which is a [flake URL][flake-url]) refers to the current flake. Thus, `nix build .#cowsay` will build the `cowsay` package from the current flake under the current system. `nix build` produces a `./result` symlink that points to the Nix store path containing the package:

```sh
$ ./result/bin/cowsay hello
 _______
< hello >
 -------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

If you run `nix build` without arguments, it will default to `.#default`.

#### DevShells


:::{.more}
To learn more,
- [Official Nix manual][mkShell]
- [NixOS Wiki](https://nixos.wiki/wiki/Development_environment_with_nix-shell)
:::

Like `packages`, another predefined flake output is `devShells` - which is used to provide a development shell aka. a nix shell or devshell. A devshell is a sandboxed environment containing the packages and other shell environment you specify. nixpkgs provides a function called [`mkShell`][mkShell] that can be used to create devshells.

As an example, we will update our `flake.nix` to provide a devshell that contains the [jq](https://github.com/stedolan/jq) tool.

```nix
{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
  };
  outputs = inputs: {
    foo = 42;
    devShells = {  # nix develop
      aarch64-darwin = {
        default =
          let 
            pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
          in pkgs.mkShell {
            nativeBuildInputs = [
              pkgs.jq
            ];
          };
      };
    };
  };
}
```

`nix flake show` will recognize this output as a "development environmenet":

```sh
$ nix flake show
path:/Users/srid/code/nixplay?lastModified=1675448105&narHash=sha256-dikTfYD1wbjc+vQ+IUTMXWv%2fm%2f7qb91Hk3ip5MNefeU=
├───devShells
│   └───aarch64-darwin
│       └───default: development environment 'nix-shell'
└───foo: unknown
```

Just as `packages` can be built using `nix build`, you can enter the devshell using [`nix develop`][nix-develop]:

```sh
$ nix develop
❯ which jq
/nix/store/33n0kx526i5dnv2gf39qv1p3a046p9yd-jq-1.6-bin/bin/jq
❯ echo '{"foo": 42}' | jq .foo
42
❯ 
```

Typing `Ctrl+D` or `exit` will exit the devshell.

## Conclusion

This mini tutorial provided a rapid introduction to Nix flakes, enabling you to get started with writing simple flake for your projects. Consult the links above for more information. There is a lot more to Nix than the concepts presented here! You can also read [Zero to Nix][zero-to-nix] for a highlevel introduction to all things Nix and flakes.

## See also

- [A (more or less) one page introduction to Nix, the language](https://github.com/tazjin/nix-1p)

[zero-to-nix]: https://zero-to-nix.com/
[nix-lang]: https://nixos.org/manual/nix/stable/language/index.html
[nix-repl]: https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-repl.html
[nix-flake-show]: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-show.html
[nix-eval]: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-eval.html
[nix-function]: https://nixos.org/manual/nix/stable/language/constructs.html#functions
[flake-url]: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#url-like-syntax
[mkShell]: https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell
[exa]: https://github.com/ogham/exa
[nix-build]: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-build.html
[nix-develop]: https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-develop.html
[NixOS]: https://nixos.org/
