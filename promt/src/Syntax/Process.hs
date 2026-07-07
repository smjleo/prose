{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveFoldable #-}
{-# LANGUAGE DeriveTraversable #-}

-- | Core process syntax for the PROMT-calculus

module Syntax.Process
  ( Role(..)
  , Label(..)
  , Prob
  , mkProb
  , probValue
  , Sort(..)
  , Expr(..)
  , Var(..)
  , Scope(..)
  , Proc(..)
  , Obligation(..)
  , Branch
  ) where

import Data.Ratio (Ratio, numerator, denominator)

-- | Participant / role identifiers (the @p@, @q@ of the calculus).
newtype Role = Role String
  deriving (Eq, Ord, Show)

-- | Branch labels (the @l_i@).
newtype Label = Label String
  deriving (Eq, Ord, Show)

-- | The coin bias of a @flip@. Always a literal rational strictly inside (0,1);
-- never an expression.
newtype Prob = Prob (Ratio Integer)
  deriving (Eq, Ord)

instance Show Prob where
  show (Prob r) = show (numerator r) ++ "/" ++ show (denominator r)

mkProb :: Ratio Integer -> Either String Prob
mkProb r
  | r <= 0 || r >= 1 = Left ("flip probability must be in (0,1), got " ++ show r)
  | otherwise        = Right (Prob r)

-- | The underlying rational of a flip bias.
probValue :: Prob -> Ratio Integer
probValue (Prob r) = r

-- | Base sorts (B, B', ... in the paper).
data Sort = SUnit | SBool | SNat | SInt
  deriving (Eq, Ord, Show)

data Expr
  = EUnit
  | EVar String
  | EBool Bool
  | ENat Integer
  | EInt Integer
  | EFlipChoice Prob Expr Expr   -- ^ e1 (+)_p e2
  | ECond Expr Expr Expr         -- ^ if c then e1 else e2  (value level)
  deriving (Eq, Ord, Show)

-- | de Bruijn variable
data Var a = BVar !Int | FVar a
  deriving (Eq, Ord, Show, Functor, Foldable, Traversable)

-- | A body under exactly one binder.
newtype Scope a = Scope (Proc a)
  deriving (Eq, Ord, Show, Functor, Foldable, Traversable)

type Branch a = (Role, Label, Sort, String, Proc a)

-- | Processes.
data Proc a
  = Nil                                
  | Sel  Role Label Expr (Proc a)      
  | Bra  [Branch a]                    
  | Flip Prob (Proc a) (Proc a)        
  | If   Expr (Proc a) (Proc a)        
  | Mu   (Scope a)                     
  | Var  (Var a)                       
  | Ghost [Obligation a] (Proc a)      
  deriving (Eq, Ord, Show, Functor, Foldable, Traversable)

-- | Typing obligations attached by 'Ghost'. Created during normalization, never
-- present in a running term.
data Obligation a
  = BoolCheck Expr        
  | TypeCheck (Proc a)    
  deriving (Eq, Ord, Show, Functor, Foldable, Traversable)
