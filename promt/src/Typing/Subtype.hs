{-# LANGUAGE LambdaCase #-}

-- | Subtyping on probabilistic session types (Image 3 rules), decided
-- coinductively with an assumption set 
--
-- Recursion (mu/TRecVar) is handled by unfolding with memoization on the pair of
-- types seen; regularity makes the set of pairs finite, so it terminates.
module Typing.Subtype
  ( subtype
  , typeEq
  ) where

import Syntax.Process (Role, Label, Sort)
import Typing.Types

-- | @subtype s t@ holds iff s <= t.
subtype :: SType -> SType -> Bool
subtype = go []
  where
    go asm s t
      | (s, t) `elem` asm           = True            -- coinductive hypothesis
      | isMu s || isMu t            = go ((s, t) : asm) (unfoldT s) (unfoldT t)
      | otherwise = case (s, t) of
          (TEnd, TEnd)             -> True
          (TRecVar i, TRecVar j)   -> i == j
          (TSel dss, TSel dts)     -> subSel asm dss dts
          (TBra bs,  TBra bt)      -> subBra asm bs bt
          _                        -> False

    -- [SUB-Sum] (+ [SUB-(+)] as the singleton case)
    subSel asm dss dts =
      all (\d -> any (\d' -> subDist asm d d') dts) dss

    -- [SUB-(+)]
    subDist asm dsub dsup =
      all (\b -> case findSel (sbRole b) (sbLabel b) dsup of
                   Just b' -> sbWeight b == sbWeight b'
                              && sbSort b == sbSort b'
                              && go asm (sbCont b) (sbCont b')
                   Nothing -> False) dsub
      &&
      all (\b' -> case findSel (sbRole b') (sbLabel b') dsub of
                    Just _  -> True
                    Nothing -> sbWeight b' == 0) dsup

    -- [SUB-&]
    subBra asm bsub bsup =
      all (\(r, l, so, t') -> case findBra r l bsub of
                                Just (so2, t2) -> so == so2 && go asm t2 t'
                                Nothing        -> False) bsup

-- | Type equality as mutual subtyping.
typeEq :: SType -> SType -> Bool
typeEq s t = subtype s t && subtype t s

-- helpers --------------------------------------------------------------------

findSel :: Role -> Label -> Dist -> Maybe SBranch
findSel r l = foldr (\b acc -> if sbRole b == r && sbLabel b == l then Just b else acc) Nothing

findBra :: Role -> Label -> [(Role, Label, Sort, SType)] -> Maybe (Sort, SType)
findBra r l = foldr (\(r2, l2, s2, t2) acc -> if r2 == r && l2 == l then Just (s2, t2) else acc) Nothing

isMu :: SType -> Bool
isMu (TMu _) = True
isMu _       = False

unfoldT :: SType -> SType
unfoldT (TMu s) = instT (TMu s) s
unfoldT t       = t

-- type-level de Bruijn machinery (only TMu binds)

shiftT :: Int -> Int -> SType -> SType
shiftT d = go
  where
    go c = \case
      TEnd            -> TEnd
      TRecVar k       -> TRecVar (if k >= c then k + d else k)
      TMu (STScope b) -> TMu (STScope (go (c + 1) b))
      TSel dss        -> TSel (map (map (onCont (go c))) dss)
      TBra bs         -> TBra (map (\(r, l, s, x) -> (r, l, s, go c x)) bs)

instT :: SType -> STScope -> SType
instT arg (STScope body) = go 0 body
  where
    go i = \case
      TEnd      -> TEnd
      TRecVar k
        | k == i    -> shiftT i 0 arg
        | k > i     -> TRecVar (k - 1)
        | otherwise -> TRecVar k
      TMu (STScope b) -> TMu (STScope (go (i + 1) b))
      TSel dss        -> TSel (map (map (onCont (go i))) dss)
      TBra bs         -> TBra (map (\(r, l, s, x) -> (r, l, s, go i x)) bs)

onCont :: (SType -> SType) -> SBranch -> SBranch
onCont f b = b { sbCont = f (sbCont b) }
