{-# LANGUAGE LambdaCase #-}

-- | Well-formedness: contractivity (guardedness) of recursion.
--
-- A recursion variable must be guarded by at least one send\/receive prefix
-- between its binder and each occurrence. Crucially a @flip@ or @if@ is NOT a
-- guard. 

module Syntax.WellFormed
  ( contractive
  , checkContractive
  ) where

import Syntax.Process

unguardedOccurs :: Int -> Proc a -> Bool
unguardedOccurs i = \case
  Var (BVar k) -> k == i
  Var (FVar _) -> False
  Nil          -> False
  Sel{}        -> False          -- prefix guards the continuation
  Bra{}        -> False          -- prefix guards the continuations
  Flip _ p q   -> unguardedOccurs i p || unguardedOccurs i q
  If _ p q     -> unguardedOccurs i p || unguardedOccurs i q
  Mu (Scope b) -> unguardedOccurs (i + 1) b
  Ghost _ p    -> unguardedOccurs i p

-- | Is the whole process contractive?
contractive :: Proc a -> Bool
contractive = \case
  Nil          -> True
  Var _        -> True
  Sel _ _ _ k  -> contractive k
  Bra bs       -> all (\(_,_,_,_,q) -> contractive q) bs
  Flip _ p q   -> contractive p && contractive q
  If _ p q     -> contractive p && contractive q
  Mu (Scope b) -> not (unguardedOccurs 0 b) && contractive b
  Ghost _ p    -> contractive p

checkContractive :: Proc a -> Either String ()
checkContractive p
  | contractive p = Right ()
  | otherwise     = Left "non-contractive recursion: a recursion variable is \
                         \reachable from its binder crossing only flip/if (no \
                         \guarding prefix)"
