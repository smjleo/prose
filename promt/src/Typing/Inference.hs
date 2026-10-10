module Typing.Inference (infer) where

import Control.Monad (unless, when)
import Data.List (sortOn)
import qualified Data.IntMap.Strict as IntMap
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Typing.Inference.Source
import Syntax.Process
import Typing.Inference.Candidate
import Typing.Expressions (sortOf)
import Typing.Relations.Matching (perfectMatching)
import qualified Typing.Relations.Graph as G
import Typing.Inference.Construct (reconstruct)
import Typing.Types (SType, Weight)

infer :: Proc String -> Either String SType
infer process = do
  source <- prepareSource process
  raw <- reconstruct source
  candidate <- compact raw
  validate source candidate
  root <- assigned candidate (sourceRoot source)
  emitType candidate (TypeRef root)

assigned :: Candidate -> Int -> Either String G.Ref
assigned candidate i = case IntMap.lookup i (sourceTypes candidate) of
  Just (TypeRef ref) -> Right ref
  Nothing -> Left ("missing source type assignment for site " ++ show i)

-- Check every original branch using its lexical recursion assumptions.
validate :: Source -> Candidate -> Either String ()
validate source candidate = do
  assignments <- IntMap.traverseWithKey (\i _ -> assigned candidate i) nodes
  let original = typeGraph candidate
      comp = G.compatibility original
      originalType i = original IntMap.! (assignments IntMap.! i)
  G.validateGraph original
  mapM_ (requireLive comp) (IntMap.toList assignments)
  plans <- IntMap.traverseWithKey (\i (p,a,b) ->
    either (Left . at i) Right (planMerge comp (probValue p) (originalType a) (originalType b)))
    (IntMap.mapMaybe flipOperands nodes)
  let pairs = Set.toAscList (Set.fromList (concatMap joinedPairs (IntMap.elems plans)))
  (joined,roots) <- G.joinGraph original comp pairs
  let joins = Map.fromList (zip pairs roots)
      resolve (Keep ref) = ref
      resolve (Join a b) = joins Map.! (a,b)
      start = maybe 0 ((+1) . fst) (IntMap.lookupMax joined)
      witnesses = IntMap.fromList (zip (IntMap.keys plans) [start..])
      expected = IntMap.fromList
        [(witnesses IntMap.! i,planNode resolve plan) | (i,plan) <- IntMap.toList plans]
      graph = IntMap.union joined expected
  -- Share equal regular trees before computing pair relations.
  (quotient,colors) <- G.compactGraph graph
  let canonical ref = colors IntMap.! ref
      compatible = G.compatibility quotient
      sub = G.subtyping quotient compatible
      equal a b = canonical a == canonical b
      below a b = equal a b || (canonical a,canonical b) `Set.member` sub
      equivalent a b = below a b && below b a
      typeAt i = graph IntMap.! (assignments IntMap.! i)
      check active binders values i = do
        when (i `Set.member` active)
          (Left (at i "cyclic source derivation (recursion must end at a variable)"))
        node <- maybe (Left (at i "missing original source node")) Right (IntMap.lookup i nodes)
        let t = assignments IntMap.! i
            descend = check (Set.insert i active) binders values
            same wanted message = unless (headsEq equal (typeAt i) wanted) (Left (at i message))
        case node of
          AEnd -> same G.NEnd "invalid termination type witness"
          ASend r l e s k -> do
            actualSort <- either (Left . at i) Right (sortOf values e)
            unless (s == actualSort) (Left (at i "send sort changed during reconstruction"))
            descend k
            same (G.NSel [[(r,l,s,1,assignments IntMap.! k)]]) "invalid send type witness"
          AReceive bs -> do
            wanted <- mapM (\(r,l,s,x,k) -> do
              check (Set.insert i active) binders ((x,s):values) k
              pure (r,l,s,assignments IntMap.! k)) bs
            same (G.NBra wanted) "invalid original receive type witness"
          AIf e a b -> do
            guardSort <- either (Left . at i) Right (sortOf values e)
            unless (guardSort == SBool) (Left (at i "if guard is not bool"))
            descend a
            descend b
            unless (below (assignments IntMap.! a) t && below (assignments IntMap.! b) t)
              (Left (at i "conditional result is not a supertype of both original arms"))
          AFlip _ a b -> do
            descend a
            descend b
            unless (matchesMerge equal equivalent resolve (plans IntMap.! i) (typeAt i))
              (Left (at i "flip reconstruction does not match the least-upper-bound merge"))
          AMu body -> do
            check (Set.insert i active) (Set.insert i binders) values body
            unless (equal t (assignments IntMap.! body))
              (Left (at i "recursive binder and body disagree"))
          AVar binder -> do
            unless (binder `Set.member` binders)
              (Left (at i "source recursion reference escaped its original binder"))
            unless (equal t (assignments IntMap.! binder))
              (Left (at i "recursion reference changed its original type identity"))
  -- Pairwise joins do not guarantee compatibility of the Cartesian output sum.
  mapM_ (requireLive compatible) [(i,canonical ref) | (i,ref) <- IntMap.toList witnesses]
  check Set.empty Set.empty [] (sourceRoot source)
  where
    nodes = sourceNodes source
    at i problem = originAt source i ++ ": " ++ problem
    requireLive relation (i,ref) = unless ((ref,ref) `Set.member` relation)
      (Left (at i "assigned type or merge result is not well formed"))
    flipOperands (AFlip p a b) = Just (p,a,b)
    flipOperands _ = Nothing

-- Copied continuations require tree equality; joined ones require subtype equivalence.
data MergeEdge = Keep G.Ref | Join G.Ref G.Ref
data MergePlan
  = MergeEnd
  | MergeInputs [(Role,Label,Sort,MergeEdge)]
  | MergeOutputs [[(Role,Label,Sort,Weight,MergeEdge)]]

planMerge :: G.Relation -> Weight -> G.Node -> G.Node -> Either String MergePlan
planMerge comp p left right = case (left,right) of
  (G.NEnd,G.NEnd) -> Right MergeEnd
  (G.NBra as,G.NBra bs) ->
    let kept = G.sharedInputs comp as bs
    in if null kept || G.roles as /= G.roles bs || Set.fromList [r | (r,_,_,_,_) <- kept] /= G.roles as
       then Left "input merge has no compatible intersection preserving every participant"
       else Right (MergeInputs [(r,l,s,Join a b) | (r,l,s,a,b) <- kept])
  (G.NSel ds,G.NSel es) -> MergeOutputs <$> sequence [distribution d e | d <- ds,e <- es]
  _ -> Left "flip cannot merge different operand constructors"
  where
    distribution as bs = do
      let leftKeys = Set.fromList (map branchKey as)
          rightKeys = Map.fromList [(branchKey b,b) | b <- bs]
      first <- mapM (\(r,l,s,w,a) -> case Map.lookup (r,l) rightKeys of
        Nothing -> Right (r,l,s,p*w,Keep a)
        Just (_,_,t,v,b)
          | s /= t -> Left "flip: shared output payload sorts differ"
          | (a,b) `Set.notMember` comp -> Left "flip: shared output continuation has no common supertype"
          | otherwise -> Right (r,l,s,p*w+(1-p)*v,Join a b)) as
      pure (first ++ [(r,l,s,(1-p)*w,Keep b) | (r,l,s,w,b) <- bs,(r,l) `Set.notMember` leftKeys])

joinedPairs :: MergePlan -> [(G.Ref,G.Ref)]
joinedPairs plan = [(a,b) | Join a b <- edges]
  where
    edges = case plan of
      MergeEnd -> []
      MergeInputs bs -> [k | (_,_,_,k) <- bs]
      MergeOutputs ds -> [k | d <- ds,(_,_,_,_,k) <- d]

planNode :: (MergeEdge -> G.Ref) -> MergePlan -> G.Node
planNode _ MergeEnd = G.NEnd
planNode ref (MergeInputs bs) = G.NBra [(r,l,s,ref k) | (r,l,s,k) <- bs]
planNode ref (MergeOutputs ds) = G.NSel [[(r,l,s,w,ref k) | (r,l,s,w,k) <- d] | d <- ds]

headsEq :: (G.Ref -> G.Ref -> Bool) -> G.Node -> G.Node -> Bool
headsEq _ G.NEnd G.NEnd = True
headsEq eq (G.NBra as) (G.NBra bs) = length as == length bs && and
  [(r,l,s)==(r',l',s') && eq a b | ((r,l,s,a),(r',l',s',b)) <- zip (inputs as) (inputs bs)]
  where inputs = sortOn (\(r,l,_,_) -> (r,l))
headsEq eq (G.NSel as) (G.NSel bs) = perfectMatching (distEq eq) as bs
headsEq _ _ _ = False

branchKey :: (Role,Label,a,b,c) -> (Role,Label)
branchKey (r,l,_,_,_) = (r,l)

distEq :: (a -> b -> Bool) -> [(Role,Label,Sort,Weight,a)]
                   -> [(Role,Label,Sort,Weight,b)] -> Bool
distEq same as bs = length as == length bs && and
  [(r,l,s,w)==(r',l',s',w') && same a b
  | ((r,l,s,w,a),(r',l',s',w',b)) <- zip (sortOn branchKey as) (sortOn branchKey bs)]

matchesMerge :: (G.Ref -> G.Ref -> Bool) -> (G.Ref -> G.Ref -> Bool)
             -> (MergeEdge -> G.Ref) -> MergePlan -> G.Node -> Bool
matchesMerge eq equivalent ref plan actual = case (plan,actual) of
  (MergeEnd,G.NEnd) -> True
  (MergeInputs bs,G.NBra _) -> headsEq equivalent (planNode ref (MergeInputs bs)) actual
  (MergeOutputs wanted,G.NSel got) -> perfectMatching (distEq continuation) wanted got
  _ -> False
  where
    continuation edge target = case edge of
      Keep original -> eq original target
      Join _ _ -> equivalent (ref edge) target
