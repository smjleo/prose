{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module PackageInfo_promt (
    name,
    version,
    synopsis,
    copyright,
    homepage,
  ) where

import Data.Version (Version(..))
import Prelude

name :: String
name = "promt"
version :: Version
version = Version [0,1,0,0] []

synopsis :: String
synopsis = "Graph-based type inference and checking for PROMT processes."
copyright :: String
copyright = "2026 Promt/ProSe contributors"
homepage :: String
homepage = ""
