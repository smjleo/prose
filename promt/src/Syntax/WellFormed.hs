{-# LANGUAGE LambdaCase #-}

module Syntax.WellFormed
  ( checkContractive
  ) where

import Syntax.Process

-- Count binders since the last communication; scope is checked separately.
contractive :: Proc a -> Bool
contractive = go 0
  where
    go unguarded = \case
      Nil          -> True
      Var (BVar k) -> k < 0 || k >= unguarded
      Var (FVar _) -> True
      Sel _ _ _ k  -> go 0 k
      Bra bs       -> all (\(_,_,_,_,q) -> go 0 q) bs
      Flip _ p q   -> go unguarded p && go unguarded q
      If _ p q     -> go unguarded p && go unguarded q
      Mu (Scope b) -> go (unguarded + 1) b

checkContractive :: Proc a -> Either String ()
checkContractive p
  | contractive p = Right ()
  | otherwise     = Left "non-contractive recursion: a recursion variable is \
                         \reachable from its binder crossing only flip/if (no \
                         \guarding prefix)"
