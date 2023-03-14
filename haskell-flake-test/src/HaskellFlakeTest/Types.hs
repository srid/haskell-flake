{-# LANGUAGE TemplateHaskell #-}

module HaskellFlakeTest.Types where

import Data.Default (Default (..))
import Optics.TH (makeLenses)

data HaskellProject = HaskellProject
  { _haskellProjectName :: Text
  , _haskellProjectPackages :: Map FilePath HaskellPackage
  , _haskellProjectCabalProject :: Maybe CabalProject
  }
  deriving stock (Show, Eq)

instance Default HaskellProject where
  def =
    HaskellProject
      { _haskellProjectName = "unnamed"
      , _haskellProjectPackages = mempty
      , _haskellProjectCabalProject = Nothing
      }

data CabalProject = CabalProject
  { cabalProjectPackages :: [Text]
  }
  deriving stock (Show, Eq)

data HaskellPackage = HaskellPackage
  { haskellPackageProvider :: HaskellPackageProvider
  , haskellPackageInfo :: CabalPackage
  }
  deriving stock (Show, Eq)

instance Default HaskellPackage where
  def = HaskellPackage {haskellPackageProvider = Cabal, haskellPackageInfo = def}

data HaskellPackageProvider = Hpack | Cabal
  deriving stock (Show, Eq)

data CabalPackage = CabalPackage
  { cabalPackageName :: Text
  , cabalPackageStanzas :: [CabalStanza]
  }
  deriving stock (Show, Eq)

instance Default CabalPackage where
  def =
    CabalPackage
      { cabalPackageName = "unnamed"
      , cabalPackageStanzas = [def]
      }

data CabalStanza
  = CabalStanza_Library [Dependency]
  | CabalStanza_Executable [Dependency]
  deriving stock (Show, Eq)

instance Default CabalStanza where
  def = CabalStanza_Library ["base"]

newtype Dependency = Dependency {unDependency :: Text}
  deriving stock (Show, Eq)
  deriving newtype (IsString)

makeLenses ''HaskellProject
