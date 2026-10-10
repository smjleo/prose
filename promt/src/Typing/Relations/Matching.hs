-- Order-insensitive matching preserves summand multiplicity.
module Typing.Relations.Matching (perfectMatching) where

import qualified Data.IntMap.Strict as IntMap
import qualified Data.IntSet as IntSet

perfectMatching :: (a -> b -> Bool) -> [a] -> [b] -> Bool
perfectMatching edge as bs
  | length as /= length bs = False
  | otherwise = matchAll (IntMap.keys adjacency) IntMap.empty
  where
    -- Cache edge tests across augmenting paths.
    adjacency = IntMap.fromDistinctAscList
      [(i, [j | (j,b) <- zip [0..] bs, edge a b]) | (i,a) <- zip [0..] as]
    adjacent i = adjacency IntMap.! i
    augment seen i matching = try seen (adjacent i)
      where
        try visited [] = (Nothing, visited)
        try visited (j:js)
          | j `IntSet.member` visited = try visited js
          | otherwise = case IntMap.lookup j matching of
              Nothing -> (Just (IntMap.insert j i matching), IntSet.insert j visited)
              Just old -> case augment (IntSet.insert j visited) old matching of
                (Just changed, visited') -> (Just (IntMap.insert j i changed), visited')
                (Nothing, visited') -> try visited' js
    matchAll [] _ = True
    matchAll (i:is) matching = case fst (augment IntSet.empty i matching) of
      Nothing -> False
      Just changed -> matchAll is changed
