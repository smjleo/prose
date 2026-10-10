{-# LANGUAGE LambdaCase #-}

module Typing.Relations (subtype, validateType) where

import qualified Data.Set as Set
import Typing.Relations.Graph
import Typing.Types

-- Check all reachable branches, including ones subsumption would discard.
validSums :: SType -> Bool
validSums t = case makeGraph [t] of
  Right (g,[a]) -> (a,a) `Set.member` compatibility g
  _ -> False

subtype :: SType -> SType -> Bool
subtype s t = case makeGraph [s,t] of
  Right (g,[a,b]) ->
    (a,b) `Set.member` subtyping g (compatibility g)
  _ -> False

-- Check closed, guarded syntax before coinductive compatibility.
validateType :: SType -> Either String ()
validateType t = do
  check [] t
  if validSums t
    then Right ()
    else Left "type has selection summands with no compatible common continuation"
  where
    -- One flag per binder: has a communication guarded it?
    check guarded = \case
      TEnd -> Right ()
      TRecVar k
        | k < 0 || k >= length guarded -> Left "type has an unbound recursion variable"
        | not (guarded !! k) -> Left "type has non-contractive recursion"
        | otherwise -> Right ()
      TMu (STScope body) -> check (False : guarded) body
      TBra bs -> do
        nonempty "branching" bs
        unique [ (r, l) | (r, l, _, _) <- bs ]
        mapM_ (\(_, _, _, c) -> check (map (const True) guarded) c) bs
      TSel ds -> do
        nonempty "selection sum" ds
        mapM_ (checkDist guarded) ds
    checkDist guarded bs = do
      nonempty "selection distribution" bs
      unique [ (sbRole b, sbLabel b) | b <- bs ]
      if any (\b -> sbWeight b <= 0 || sbWeight b > 1) bs
        then Left "selection probabilities must be in (0,1]"
        else Right ()
      if sum (map sbWeight bs) /= 1
        then Left "selection probabilities must sum to 1"
        else Right ()
      mapM_ (check (map (const True) guarded) . sbCont) bs
    nonempty what xs
      | null xs = Left (what ++ " must be nonempty")
      | otherwise = Right ()
    unique keys
      | Set.size (Set.fromList keys) /= length keys =
          Left "type has duplicate (role,label) branches"
      | otherwise = Right ()
