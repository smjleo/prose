{-# LANGUAGE LambdaCase #-}

-- | Regular-tree equivalence: equality of the (possibly infinite) trees that
-- two processes unfold to. Decidable because equirecursive terms are regular
-- (finitely many distinct subterms up to unfolding), so the set of pairs we
-- ever compare is finite and the seen-set guarantees termination.

module Syntax.RegularTree
  ( regularTreeEq
  ) where

import           Data.Set (Set)
import qualified Data.Set as Set
import           Syntax.Process
import           Syntax.Binder (unfold)

-- | Are these two processes regular-tree-equivalent?
regularTreeEq :: Ord a => Proc a -> Proc a -> Bool
regularTreeEq = go Set.empty
  where
    go :: Ord a => Set (Proc a, Proc a) -> Proc a -> Proc a -> Bool
    go seen p0 q0
      | (p0, q0) `Set.member` seen = True              -- knot tied: assume equal
      | otherwise =
          let seen' = Set.insert (p0, q0) seen
              p = whnf p0
              q = whnf q0
          in eqHead seen' p q

    whnf :: Proc a -> Proc a
    whnf p@(Mu _) = whnf (unfold p)
    whnf p        = p

    eqHead seen p q = case (p, q) of
      (Nil, Nil) -> True
      (Sel r1 l1 e1 c1, Sel r2 l2 e2 c2) ->
        r1 == r2 && l1 == l2 && e1 == e2 && go seen c1 c2
      (Bra bs1, Bra bs2) -> eqBranches seen bs1 bs2
      (Flip p1 a1 b1, Flip p2 a2 b2) ->   -- positional: H vs T
        p1 == p2 && go seen a1 a2 && go seen b1 b2
      (If e1 a1 b1, If e2 a2 b2) ->
        e1 == e2 && go seen a1 a2 && go seen b1 b2
      (Var v1, Var v2) -> v1 == v2
      (Ghost _ p', _)  -> go seen p' q   -- Ghost is transparent to the tree
      (_, Ghost _ q')  -> go seen p q'
      _ -> False

    -- Branch sets must agree as sets keyed by (role,label), with equal sorts and
    -- equal continuations.
    eqBranches seen bs1 bs2 =
      length bs1 == length bs2 &&
      all (\(r1, l1, s1, _, c1) ->
             case [ (s2, c2) | (r2, l2, s2, _, c2) <- bs2, r2 == r1, l2 == l1 ] of
               ((s2, c2) : _) -> s1 == s2 && go seen c1 c2
               []             -> False) bs1
