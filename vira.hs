-- CI configuration <https://vira.nixos.asia/>
\ctx pipeline ->
  let
    isMaster = ctx.branch == "master"
    hf = [("haskell-flake", ".")]
  in pipeline
     { build.systems =
        [ "x86_64-linux"
        , "aarch64-darwin"
        ]
     , build.flakes =
         [ "./dev" { overrideInputs = hf }
         , "./doc" { overrideInputs = hf }
         , "./example" { overrideInputs = hf }
         , "./nix/haskell-parsers/test" { overrideInputs = [("haskell-parsers", "path:./nix/haskell-parsers")] }
         , "./test/simple" { overrideInputs = hf }
         , "./test/cabal2nix" { overrideInputs = hf }
         , "./test/with-subdir" { overrideInputs = hf }
         , "./test/project-module" { overrideInputs = hf }
         , "./test/settings-defaults" { overrideInputs = hf }
         , "./test/otherOverlays" { overrideInputs = hf }
         ]
     , signoff.enable = True
     , cache.url = if isMaster then Just "https://cache.nixos.asia/oss" else Nothing
     }
