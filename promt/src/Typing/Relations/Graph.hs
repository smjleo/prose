{-# LANGUAGE LambdaCase #-}

module Typing.Relations.Graph
  ( Ref, Node(..), Graph, Relation
  , makeGraph, validateGraph, compactGraph
  , compatibility, subtyping
  , sharedInputs, roles, joinGraph
  ) where

import Control.Monad (foldM)
import Data.List (sort, sortOn)
import qualified Data.IntMap.Strict as IntMap
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Syntax.Process (Role, Label, Sort)
import Typing.Types

-- Recursion edges retain each input type’s separate lexical scope.
type Ref = Int
type GBranch = (Role, Label, Sort, Weight, Ref)
data Node
  = NEnd
  | NSel [[GBranch]]
  | NBra [(Role, Label, Sort, Ref)]
  | Alias Ref
  | Invalid
  deriving (Eq, Ord, Show)
type Graph = IntMap.IntMap Node
type Relation = Set.Set (Ref, Ref)

newtype Build a = Build { runBuild :: (Int, Graph) -> (a, (Int, Graph)) }
instance Functor Build where
  fmap f (Build g) = Build $ \s -> let (a, s') = g s in (f a, s')
instance Applicative Build where
  pure a = Build $ \s -> (a, s)
  Build f <*> Build g = Build $ \s ->
    let (h, s1) = f s; (a, s2) = g s1 in (h a, s2)
instance Monad Build where
  Build g >>= f = Build $ \s ->
    let (a, s1) = g s in runBuild (f a) s1

newNode :: Node -> Build Ref
newNode n = Build $ \(i, ns) -> (i, (i + 1, IntMap.insert i n ns))
setNode :: Ref -> Node -> Build ()
setNode i n = Build $ \(j, ns) -> ((), (j, IntMap.insert i n ns))

buildType :: [Ref] -> SType -> Build Ref
buildType env = \case
  TEnd -> newNode NEnd
  TRecVar k
    | k < 0 -> newNode Invalid
    | k < length env -> pure (env !! k)
    | otherwise -> newNode Invalid
  TMu (STScope body) -> do
    i <- newNode Invalid
    b <- buildType (i : env) body
    setNode i (Alias b)
    pure i
  TSel ds -> do
    ds' <- mapM (mapM $ \b -> do
      c <- buildType env (sbCont b)
      pure (sbRole b, sbLabel b, sbSort b, sbWeight b, c)) ds
    newNode (NSel ds')
  TBra bs -> do
    bs' <- mapM (\(r, l, so, t) -> do
      c <- buildType env t
      pure (r, l, so, c)) bs
    newNode (NBra bs')

makeGraph :: [SType] -> Either String (Graph, [Ref])
makeGraph ts = do
  let (roots, (_, raw)) = runBuild (mapM (buildType []) ts) (0, IntMap.empty)
      -- Memoize alias heads to avoid retraversing suffixes.
      chase seen memo i
        | i `Set.member` seen = Left "noncontractive recursive type"
        | Just headRef <- IntMap.lookup i memo = Right (headRef,memo)
        | otherwise = do
            (headRef,next) <- case IntMap.lookup i raw of
              Just (Alias j) -> chase (Set.insert i seen) memo j
              Just Invalid -> Left "invalid recursion variable"
              Just _ -> Right (i,memo)
              Nothing -> Left "invalid type graph edge"
            pure (headRef,IntMap.insert i headRef next)
      resolve memo i = snd <$> chase Set.empty memo i
  heads <- foldM resolve IntMap.empty (IntMap.keys raw)
  let ref i = heads IntMap.! i
      edge = ref
      canon = \case
        NSel ds -> NSel [[(r, l, so, w, edge c) | (r,l,so,w,c) <- d] | d <- ds]
        NBra bs -> NBra [(r,l,so,edge c) | (r,l,so,c) <- bs]
        n -> n
      graph = IntMap.fromList
        [(i, canon n) | (i,n) <- IntMap.toList raw, ref i == i]
  (compact,renaming) <- compactGraph graph
  pure (compact, map ((renaming IntMap.!) . ref) roots)

validNode :: Node -> Bool
validNode (NSel ds) = not (null ds) && all validDist ds
  where
    validDist d = not (null d)
      && unique [(r,l) | (r,l,_,_,_) <- d]
      && all (\(_,_,_,w,_) -> w > 0 && w <= 1) d
      && sum [w | (_,_,_,w,_) <- d] == 1
validNode (NBra bs) = not (null bs) && unique [(r,l) | (r,l,_,_) <- bs]
validNode NEnd = True
validNode _ = False

-- Check constructors and edge targets; compatibility checks sums separately.
validateGraph :: Graph -> Either String ()
validateGraph g
  | not (all validNode (IntMap.elems g)) =
      Left "ill-formed type: empty or duplicate branches, or invalid distribution weights"
  | not (all (`IntMap.member` g) (concatMap children (IntMap.elems g))) =
      Left "invalid type graph edge"
  | otherwise = Right ()
  where
    children (NSel ds) = [c | d <- ds, (_,_,_,_,c) <- d]
    children (NBra bs) = [c | (_,_,_,c) <- bs]
    children _ = []

-- Partition refinement preserves summand multiplicity while ignoring order.
compactGraph :: Graph -> Either String (Graph, IntMap.IntMap Ref)
compactGraph graph = do
  validateGraph graph
  pure (IntMap.fromList
          [(rename ref,mapRefs rename node) | (ref,node) <- IntMap.toAscList graph],
        colors)
  where
    colors = settle (IntMap.map (const 0) graph)
    rename ref = colors IntMap.! ref
    settle old =
      let (_,next) = IntMap.mapAccumWithKey (classify old) Map.empty graph
      in if next == old then old else settle next
    classify old classes ref node =
      let signature = (old IntMap.! ref, ordered (mapRefs (old IntMap.!) node))
      in case Map.lookup signature classes of
        Just color -> (classes,color)
        Nothing -> let color = Map.size classes
                   in (Map.insert signature color classes,color)
    ordered (NSel ds) = NSel (sort (map sort ds))
    ordered (NBra bs) = NBra (sort bs)
    ordered n = n

mapRefs :: (Ref -> Ref) -> Node -> Node
mapRefs f (NSel ds) = NSel [[(r,l,s,w,f c) | (r,l,s,w,c) <- d] | d <- ds]
mapRefs f (NBra bs) = NBra [(r,l,s,f c) | (r,l,s,c) <- bs]
mapRefs f (Alias c) = Alias (f c)
mapRefs _ n = n

unique :: Ord a => [a] -> Bool
unique xs = Set.size (Set.fromList xs) == length xs
roles :: [(Role, Label, Sort, Ref)] -> Set.Set Role
roles bs = Set.fromList [r | (r,_,_,_) <- bs]

-- Greatest fixed point: settle compatibility before building joins.
fixedRelation :: Graph -> (Relation -> (Ref, Ref) -> Bool) -> Relation
fixedRelation g step = settle initial
  where
    -- Partition by constructor and participant set before pairing.
    groups = Map.fromListWith (++)
      [(shape node,[i]) | (i,node) <- IntMap.toList g]
    initial = Set.fromList
      [(a,b) | (Just _,ids) <- Map.toList groups, a <- ids, b <- ids]
    settle rel = let next = Set.filter (step rel) rel
                 in if next == rel then rel else settle next
    shape NEnd = Just (0 :: Int, Set.empty)
    shape (NSel _) = Just (1, Set.empty)
    shape (NBra bs) = Just (2, roles bs)
    shape _ = Nothing

sharedGraph :: [[GBranch]] -> [(GBranch, GBranch)]
sharedGraph ds =
  [(b,c) | occurrences <- Map.elems byKey,
           (i,b) <- occurrences, (j,c) <- occurrences, i < j]
  where
    byKey = Map.fromListWith (++)
      [((r,l),[(i,b)]) | (i,d) <- zip [(0 :: Int)..] ds, b@(r,l,_,_,_) <- d]

sumWF :: Relation -> [[GBranch]] -> Bool
sumWF rel ds = all match (sharedGraph ds)
  where match ((_,_,s,_,a),(_,_,t,_,b)) = s == t && (a,b) `Set.member` rel

-- All original continuations must be valid, including dropped input branches.
nodeWF :: Relation -> Node -> Bool
nodeWF rel (NSel ds) = sumWF rel ds
  && all (\(_,_,_,_,c) -> (c,c) `Set.member` rel) (concat ds)
nodeWF rel (NBra bs) = all (\(_,_,_,c) -> (c,c) `Set.member` rel) bs
nodeWF _ _ = True

sharedInputs :: Relation -> [(Role, Label, Sort, Ref)]
             -> [(Role, Label, Sort, Ref)] -> [(Role, Label, Sort, Ref, Ref)]
sharedInputs rel as bs =
  [(r,l,s,a,b) | (r,l,s,a) <- as, Just (s',b) <- [Map.lookup (r,l) right],
                 s == s', (a,b) `Set.member` rel]
  where right = Map.fromList [((r,l),(s,b)) | (r,l,s,b) <- bs]

compatibility :: Graph -> Relation
compatibility g = fixedRelation g $ \rel ->
  -- Cache validity per node per iteration.
  let wellFormed = IntMap.map (nodeWF rel) g
  in \(a,b) -> wellFormed IntMap.! a && wellFormed IntMap.! b &&
    case (g IntMap.! a,g IntMap.! b) of
      (NEnd,NEnd) -> True
      (NSel ds,NSel es) -> sumWF rel (ds ++ es)
      (NBra as,NBra bs) ->
        let kept = sharedInputs rel as bs
        in not (null kept) && roles as == roles bs
           && Set.fromList [r | (r,_,_,_,_) <- kept] == roles as
      _ -> False

orderDist :: [GBranch] -> [GBranch]
orderDist = sortOn (\(r,l,_,_,_) -> (r,l))

-- Sort branches once, outside descending iteration.
orderedGraph :: Graph -> Graph
orderedGraph = IntMap.map $ \case
  NSel ds -> NSel (map orderDist ds)
  n -> n

-- Support, weights and sorts agree; continuations vary covariantly.
distBelow :: Relation -> [GBranch] -> [GBranch] -> Bool
distBelow rel as bs = length as == length bs && and (zipWith match as bs)
  where
    match (r,l,s,w,a) (r',l',s',w',b) =
      (r,l,s,w) == (r',l',s',w') && (a,b) `Set.member` rel

subtyping :: Graph -> Relation -> Relation
subtyping original comp = fixedRelation g $ \sub (i,j) ->
  (i,i) `Set.member` comp && (j,j) `Set.member` comp &&
  case (g IntMap.! i,g IntMap.! j) of
    (NEnd,NEnd) -> True
    (NSel ds,NSel es) -> all (\d -> any (distBelow sub d) es) ds
    (NBra as,NBra bs) -> roles as == roles bs
      && all (\(r,l,so,c) -> any (\(r',l',so',d) ->
           (r,l,so) == (r',l',so') && (d,c) `Set.member` sub) as) bs
    _ -> False
  where g = orderedGraph original

-- Memoize input joins; concatenate output summands without deduplication.
joinGraph :: Graph -> Relation -> [(Ref, Ref)] -> Either String (Graph, [Ref])
joinGraph g comp pairs = do
  (roots,(_,result,_)) <- buildMany join pairs (next,g,Map.empty)
  pure (result,roots)
  where
    next = maybe 0 ((+ 1) . fst) (IntMap.lookupMax g)
    join pair@(a,b) state@(fresh,nodes,memo)
      | pair `Set.notMember` comp = Left "type graph join: no common supertype"
      | otherwise = case Map.lookup pair memo of
          Just ref -> Right (ref,state)
          Nothing -> do
            -- Reserve before descent to close cycles.
            let pending = (fresh + 1, IntMap.insert fresh Invalid nodes,
                           Map.insert pair fresh memo)
            (node,(newNext,newNodes,newMemo)) <- case (IntMap.lookup a g,IntMap.lookup b g) of
              (Just NEnd,Just NEnd) -> Right (NEnd,pending)
              (Just (NSel ds),Just (NSel es)) -> Right (NSel (ds ++ es),pending)
              (Just (NBra as),Just (NBra bs)) -> do
                let branches = sharedInputs comp as bs
                    input (r,l,s,c,d) st = do
                      (ref,st') <- join (c,d) st
                      pure ((r,l,s,ref),st')
                (joined,st') <- buildMany input branches pending
                pure (NBra joined,st')
              _ -> Left "type graph join: invalid compatible pair"
            pure (fresh,(newNext,IntMap.insert fresh node newNodes,newMemo))

buildMany :: (a -> s -> Either String (b,s)) -> [a] -> s -> Either String ([b],s)
buildMany _ [] state = Right ([],state)
buildMany f (x:xs) state = do
  (y,next) <- f x state
  (ys,final) <- buildMany f xs next
  pure (y:ys,final)
