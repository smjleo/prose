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
  , Branch
  ) where

import Data.Ratio (Ratio, numerator, denominator)

newtype Role = Role String
  deriving (Eq, Ord, Show)

newtype Label = Label String
  deriving (Eq, Ord, Show)

newtype Prob = Prob (Ratio Integer)
  deriving (Eq, Ord)

instance Show Prob where
  show (Prob r) = show (numerator r) ++ "/" ++ show (denominator r)

-- Flip biases must lie in (0,1).
mkProb :: Ratio Integer -> Either String Prob
mkProb r
  | r <= 0 || r >= 1 = Left ("flip probability must be in (0,1), got " ++ show r)
  | otherwise        = Right (Prob r)

probValue :: Prob -> Ratio Integer
probValue (Prob r) = r

data Sort = SUnit | SBool | SNat | SInt | SStr
  deriving (Eq, Ord, Show)

data Expr
  = EUnit
  | EVar String
  | EBool Bool
  | EInt Integer
  | ENot Expr
  | EOr  Expr Expr
  | EAnd Expr Expr
  | EAdd Expr Expr
  | ESucc Expr
  | ENeg Expr
  | EEq Expr Expr
  | EGt Expr Expr
  | ELt Expr Expr
  deriving (Eq, Ord, Show)

-- Bound de Bruijn index, or a source name awaiting abstraction.
data Var a = BVar !Int | FVar a
  deriving (Eq, Ord, Show)

-- Index 0 refers to this binder.
newtype Scope a = Scope (Proc a)
  deriving (Eq, Ord, Show)

type Branch a = (Role, Label, Sort, String, Proc a)

data Proc a
  = Nil
  | Sel  Role Label Expr (Proc a)
  | Bra  [Branch a]
  | Flip Prob (Proc a) (Proc a)
  | If   Expr (Proc a) (Proc a)
  | Mu   (Scope a)
  | Var  (Var a)
  deriving (Eq, Ord, Show)

