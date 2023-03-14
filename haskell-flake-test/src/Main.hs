module Main where

import Data.Default
import HaskellFlakeTest.Scaffold (HasScaffold (scaffold))
import HaskellFlakeTest.Types
import Main.Utf8 qualified as Utf8
import Optics.Core ((.~))

simpleProject :: HaskellProject
simpleProject =
  let pkg = def
   in def & haskellProjectPackages .~ one (".", pkg)

{- |
 Main entry point.

 The `, run` script will invoke this function.
-}
main :: IO ()
main = do
  -- For withUtf8, see https://serokell.io/blog/haskell-with-utf8
  Utf8.withUtf8 $ do
    scaffold "/tmp/haskell-flake-test" simpleProject
