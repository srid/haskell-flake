{-# LANGUAGE RecordWildCards #-}

module HaskellFlakeTest.Scaffold where

import Data.Map.Strict qualified as Map
import HaskellFlakeTest.Types
import System.Directory (createDirectoryIfMissing)
import System.FilePath

-- Scaffold a directory layout for the given entity.
class HasScaffold a where
  scaffold :: FilePath -> a -> IO ()

instance HasScaffold HaskellPackage where
  scaffold fp pkg@HaskellPackage {..} = do
    createDirectoryIfMissing True fp
    case haskellPackageProvider of
      Hpack -> do
        writeFileText (fp </> "package.yaml") "TODO"
      Cabal -> do
        let name = cabalPackageName haskellPackageInfo
        writeFileText (fp </> toString name <> ".cabal") "TODO"
    -- TODO
    putTextLn $ "Generating package " <> toText fp <> " : " <> show @Text pkg

instance HasScaffold HaskellProject where
  scaffold fp prj@HaskellProject {..} = do
    forM_ (Map.toList _haskellProjectPackages) $ \(path, pkg) -> do
      scaffold (fp </> path) pkg
    -- TODO
    putTextLn $ "Generating project " <> toText fp <> " : " <> show @Text prj