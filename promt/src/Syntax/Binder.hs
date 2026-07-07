{-# LANGUAGE LambdaCase #-}

module Syntax.Binder
  ( shift
  , instantiate
  , abstract
  , unfold
  ) where

import Syntax.Process

shift :: Int -> Int -> Proc a -> Proc a
shift d = go
  where
    go c = \case
      Nil            -> Nil
      Sel r l e p    -> Sel r l e (go c p)
      Bra bs         -> Bra [ (r, l, so, vx, go c q) | (r, l, so, vx, q) <- bs ]
      Flip pr p q    -> Flip pr (go c p) (go c q)
      If e p q       -> If e (go c p) (go c q)
      Mu (Scope b)   -> Mu (Scope (go (c + 1) b))
      Var v          -> Var (shiftVar c v)
      Ghost os p     -> Ghost (map (shiftOb c) os) (go c p)

    shiftVar c (BVar k) | k >= c    = BVar (k + d)
                        | otherwise = BVar k
    shiftVar _ (FVar x)             = FVar x

    shiftOb c (BoolCheck e) = BoolCheck e
    shiftOb c (TypeCheck q) = TypeCheck (go c q)

instantiate :: Proc a -> Scope a -> Proc a
instantiate r (Scope body) = go 0 body
  where
    go i = \case
      Nil            -> Nil
      Sel ro l e p   -> Sel ro l e (go i p)
      Bra bs         -> Bra [ (r, l, so, vx, go i q) | (r, l, so, vx, q) <- bs ]
      Flip pr p q    -> Flip pr (go i p) (go i q)
      If e p q       -> If e (go i p) (go i q)
      Mu (Scope b)   -> Mu (Scope (go (i + 1) b))
      Var (BVar k)
        | k == i     -> shift i 0 r
        | k > i      -> Var (BVar (k - 1))   -- this binder is being consumed
        | otherwise  -> Var (BVar k)
      Var (FVar x)   -> Var (FVar x)
      Ghost os p     -> Ghost (map (goOb i) os) (go i p)

    goOb i (BoolCheck e) = BoolCheck e
    goOb i (TypeCheck q) = TypeCheck (go i q)

-- | @abstract@ turns a free recursion name into bound index 0
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
      Ghost os q     -> Ghost (map (goOb i) os) (go i q)

    goOb i (BoolCheck e) = BoolCheck e
    goOb i (TypeCheck q) = TypeCheck (go i q)

-- | One-step equirecursive unfolding
unfold :: Proc a -> Proc a
unfold p@(Mu s) = instantiate p s
unfold p        = p
