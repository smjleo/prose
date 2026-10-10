{-# LANGUAGE LambdaCase #-}

module Syntax.Binder (abstract) where

import Syntax.Process

-- @abstract@ binds a free recursion name at index 0.
abstract :: Eq a => a -> Proc a -> Scope a
abstract name p = Scope (go 0 p)
  where
    go i = \case
      Nil            -> Nil
      Sel ro l e q   -> Sel ro l e (go i q)
      Bra bs         -> Bra [ (r, l, so, vx, go i q) | (r, l, so, vx, q) <- bs ]
      Flip pr a b    -> Flip pr (go i a) (go i b)
      If e a b       -> If e (go i a) (go i b)
      Mu (Scope b)   -> Mu (Scope (go (i + 1) b))
      Var (FVar x)
        | x == name  -> Var (BVar i)
        | otherwise  -> Var (FVar x)
      Var (BVar k)   -> Var (BVar k)

