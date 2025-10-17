-- CI configuration <https://vira.nixos.asia/>
\ctx pipeline ->
  let
    isMaster = ctx.branch == "master"
  in pipeline
     { build.flakes =
         [ "./dev" { overrideInputs = [("haskell-flake", ".")] }
         , "./doc" { overrideInputs = [("haskell-flake", ".")] }
         , "./example" { overrideInputs = [("haskell-flake", ".")] }
         , "./nix/haskell-parsers/test" { overrideInputs = [("haskell-parsers", "./nix/haskell-parsers")] }
         , "./test/simple" { overrideInputs = [("haskell-flake", ".")] }
         , "./test/cabal2nix" { overrideInputs = [("haskell-flake", ".")] }
         , "./test/with-subdir" { overrideInputs = [("haskell-flake", ".")] }
         , "./test/project-module" { overrideInputs = [("haskell-flake", ".")] }
         , "./test/settings-defaults" { overrideInputs = [("haskell-flake", ".")] }
         , "./test/otherOverlays" { overrideInputs = [("haskell-flake", ".")] }
         ]
     , signoff.enable = True
     , cache.url = if isMaster then Just "https://cache.nixos.asia/oss" else Nothing
     }
