module Typing.Types
  ( Weight
  , SBranch(..)
  , Dist
  , STScope(..)
  , SType(..)
  ) where

import Data.Ratio (Ratio)
import Syntax.Process (Role, Label, Sort)

type Weight = Ratio Integer

data SBranch = SBranch
  { sbRole   :: Role
  , sbWeight :: Weight
  , sbLabel  :: Label
  , sbSort   :: Sort
  , sbCont   :: SType
  } deriving (Eq, Ord, Show)

-- Nonempty, unique keys, positive weights summing to 1.
type Dist = [SBranch]

newtype STScope = STScope SType
  deriving (Eq, Ord, Show)

data SType
  = TEnd
  | TSel [Dist]
  | TBra [(Role, Label, Sort, SType)]
  | TMu STScope
  | TRecVar Int  -- de Bruijn index
  deriving (Eq, Ord, Show)
