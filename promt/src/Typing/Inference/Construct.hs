-- | Continuation-goal construction; original-source validation follows separately.
module Typing.Inference.Construct (reconstruct) where

import Control.Monad (foldM)
import qualified Data.IntMap.Strict as IM
import qualified Data.IntSet as IS
import Data.List (foldl', sortOn)
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import Typing.Inference.Source
import Syntax.Process (Role, Label, Sort, probValue)
import Typing.Inference.Candidate
import Typing.Types (Weight)

-- LUB goals deduplicate source sites; distribution lists retain multiplicity.
newtype Goal = Goal IS.IntSet deriving (Eq, Ord, Show)
data Out r = Out Role Label Sort Weight r deriving (Eq, Show)
data Input r = Input Role Label Sort r (S.Set r) deriving (Eq, Show)
data Head r = End | Selection [[Out r]] | InputHead (S.Set Role) [Input r]
            | Invalid String deriving (Eq, Show)
data Conflict = Conflict Int String

type Heads = IM.IntMap (Head Goal)
type Relation = S.Set (Int,Int)
type Graph = IM.IntMap (Head Int)
data Build = Build Heads [Conflict]

reconstruct :: Source -> Either String Candidate
reconstruct source = case exposeAll source of
  Left problem -> Left problem
  Right (heads,conflicts) ->
    let seeds = map single (IM.keys (sourceNodes source))
        shapes = foldl' (close heads) M.empty seeds
    in finish source shapes conflicts
  where
    -- Finitely many subset goals; memoize before descent to close cycles.
    close heads known goal@(Goal ids)
      | M.member goal known = known
      | otherwise =
          let node = joinHeads [heads IM.! i | i <- IS.toAscList ids]
              known' = M.insert goal node known
          in foldl' (close heads) known' (headRefs node)

single :: Int -> Goal
single = Goal . IS.singleton

joinGoals :: [Goal] -> Goal
joinGoals goals = Goal (IS.unions [ids | Goal ids <- goals])

-- Stop at communications; contractiveness excludes silent cycles.
exposeAll :: Source -> Either String (Heads,[Conflict])
exposeAll source = do
  Build heads conflicts <- foldM exposeOne (Build IM.empty []) (IM.keys (sourceNodes source))
  pure (heads,conflicts)
  where
    exposeOne state i = snd <$> headAt IS.empty i state
    headAt active i state@(Build known _) = case IM.lookup i known of
      Just h -> Right (h,state)
      Nothing
        | i `IS.member` active -> Left (originAt source i ++ ": unguarded source cycle")
        | otherwise -> do
          (h,Build known' pending) <- expose (IS.insert i active) i (sourceNodes source IM.! i) state
          pure (h,Build (IM.insert i h known') pending)
    expose active i node state = case node of
      AEnd -> pure (End,state)
      ASend r l _ s k -> pure (Selection [[Out r l s 1 (single k)]],state)
      AReceive bs -> pure (InputHead (S.fromList [r | (r,_,_,_,_) <- bs])
        [Input r l s (single k) (S.singleton (single k)) | (r,l,s,_,k) <- bs],state)
      AMu k -> headAt active k state
      AVar k -> headAt active k state
      AIf _ a b -> operands active a b state $ \x y next ->
        pure (joinHeads [x,y],next)
      AFlip p a b -> operands active a b state $ \x y next ->
        pure (flipHeads i (probValue p) x y next)
    operands active a b state use = do
      (x,next) <- headAt active a state
      (y,done) <- headAt active b next
      use x y done
    flipHeads i p (Selection ds) (Selection es) (Build hs pending) =
      let pairs = [mergeDist i p d e | d <- ds, e <- es]
      in (Selection (map fst pairs),Build hs (concatMap snd pairs ++ pending))
    -- Input merge preserves participants; all original source goals must survive.
    flipHeads _ _ x@(InputHead _ _) y@(InputHead _ _) state =
      (joinHeads [x,y],state)
    flipHeads _ _ End End state = (End,state)
    flipHeads _ _ (Invalid e) _ state = (Invalid e,state)
    flipHeads _ _ _ (Invalid e) state = (Invalid e,state)
    flipHeads _ _ _ _ state = (Invalid "flip cannot merge different operand constructors",state)

joinHeads :: [Head Goal] -> Head Goal
joinHeads [] = Invalid "empty join goal"
joinHeads [h] = h
joinHeads hs
  | all isEnd hs = End
  | Just ds <- mapM selections hs = Selection (concat ds)
  | Just bs <- mapM inputs hs = case bs of
      (roles,first):others
        | any ((/= roles) . fst) others -> Invalid "input join participant sets differ"
        | otherwise -> InputHead roles
            [ Input r l s next (S.insert next (S.unions guards))
            | a@(Input r l s _ _) <- first
            , Just matched <- [mapM (findInput a . snd) others]
            , let allInputs = a:matched
                  next = joinGoals [k | Input _ _ _ k _ <- allInputs]
                  guards = [guard | Input _ _ _ _ guard <- allInputs] ]
      [] -> Invalid "empty input join"
  | otherwise = Invalid "if join: operand constructors have no common supertype"
  where
    isEnd End = True
    isEnd _ = False
    selections (Selection ds) = Just ds
    selections _ = Nothing
    inputs (InputHead rs bs) = Just (rs,bs)
    inputs _ = Nothing
    findInput (Input r l s _ _) bs = case
      [b | b@(Input r' l' s' _ _) <- bs, (r,l,s) == (r',l',s')] of
      [b] -> Just b
      _ -> Nothing

mergeDist :: Int -> Weight -> [Out Goal] -> [Out Goal]
          -> ([Out Goal],[Conflict])
mergeDist i p left right = (sortOn outKey (shared ++ ls ++ rs), obligations)
  where
    -- Lists preserve duplicate keys for later validity checks.
    rightByKey = foldr (\b -> M.insertWith (++) (outKey b) [b]) M.empty right
    leftKeys = S.fromList (map outKey left)
    pairs = [(a,b) | a <- left, b <- M.findWithDefault [] (outKey a) rightByKey]
    shared = [Out r l s (p*w+(1-p)*v) (joinGoals [k,next])
             | (Out r l s w k,Out _ _ _ v next) <- pairs]
    ls = [Out r l s (p*w) k | a@(Out r l s w k) <- left,
                            outKey a `M.notMember` rightByKey]
    rs = [Out r l s ((1-p)*w) k | a@(Out r l s w k) <- right,
                                outKey a `S.notMember` leftKeys]
    obligations = [Conflict i "flip: shared output payload sorts differ"
                  | (Out _ _ s _ _,Out _ _ t _ _) <- pairs, s /= t]

outKey :: Out r -> (Role,Label)
outKey (Out r l _ _ _) = (r,l)
headRefs :: Ord r => Head r -> [r]
headRefs End = []
headRefs (Invalid _) = []
headRefs (Selection ds) = [k | Out _ _ _ _ k <- concat ds]
headRefs (InputHead _ bs) = S.toList (S.unions [S.insert k guard | Input _ _ _ k guard <- bs])

mapHead :: Ord b => (a -> b) -> Head a -> Head b
mapHead _ End = End
mapHead _ (Invalid e) = Invalid e
mapHead f (Selection ds) = Selection [[Out r l s w (f k) | Out r l s w k <- d] | d <- ds]
mapHead f (InputHead rs bs) = InputHead rs
  [Input r l s (f k) (S.fromList (map f (S.toList guard))) | Input r l s k guard <- bs]

-- Greatest fixed point: (g,g) means live; input guards retain source obligations.
-- Required participant sets never shrink.
compatibleGoals :: Graph -> Relation
compatibleGoals graph = settle initial
  where
    initial = S.fromList [(a,b) | (a,x) <- IM.toList graph, (b,y) <- IM.toList graph, shape x y]
    shape End End = True
    shape (Selection _) (Selection _) = True
    shape (InputHead rs _) (InputHead ss _) = not (S.null rs) && rs == ss
    shape _ _ = False
    settle rel =
      let valid = IM.map (\h -> case h of
            Selection ds -> validOutputs rel ds
            _ -> True) graph
          next = S.filter (step rel valid) rel
      in if next == rel then rel else settle next
    step rel valid (a,b) = case (graph IM.! a,graph IM.! b) of
      (End,End) -> True
      (Selection ds,Selection es) -> valid IM.! a && valid IM.! b &&
        and [distCompatible rel d e | d <- ds, e <- es]
      (InputHead rs as,InputHead _ bs) ->
        S.fromList [r | Input r l s k guard <- as, enabled rel guard,
                       Input r' l' s' v guard' <- bs, enabled rel guard',
                       (r,l,s) == (r',l',s'), (k,v) `S.member` rel] == rs
      _ -> False
    validOutputs rel ds = not (null ds) && all (validDist rel) ds && sumCompatible rel ds
    validDist rel d = not (null d) && S.size (S.fromList (map outKey d)) == length d &&
      all (\(Out _ _ _ w k) -> w > 0 && w <= 1 && live rel k) d &&
      sum [w | Out _ _ _ w _ <- d] == 1
    sumCompatible rel ds = and
      [distCompatible rel d e | (n,d) <- zip [(0::Int)..] ds, e <- drop (n+1) ds]
    distCompatible rel d e = and
      [s == t && (k,v) `S.member` rel
      | a@(Out _ _ s _ k) <- d, b@(Out _ _ t _ v) <- e, outKey a == outKey b]

live :: Relation -> Int -> Bool
live rel k = (k,k) `S.member` rel
enabled :: Relation -> S.Set Int -> Bool
enabled rel = all (live rel) . S.toList

finish :: Source -> M.Map Goal (Head Goal) -> [Conflict] -> Either String Candidate
finish source shapes conflicts = case mapM_ requireSource (IM.keys (sourceNodes source)) of
  Left problem -> Left problem
  Right () -> case conflicts of
    Conflict i message:_ -> Left (originAt source i ++ ": " ++ message)
    [] -> Right Candidate
      { candidateGraph = M.fromList
          [(TypeRef i,emit h) | (i,h) <- IM.toList graph, live relation i]
      , sourceTypes = IM.mapWithKey (\i _ -> TypeRef (ref (single i))) (sourceNodes source)
      }
  where
    ids = M.fromList (zip (M.keys shapes) [0..])
    ref goal = ids M.! goal
    graph = IM.fromList [(ref g,mapHead ref h) | (g,h) <- M.toList shapes]
    relation = compatibleGoals graph
    requireSource i
      | live relation (ref (single i)) = Right ()
      | otherwise = Left (originAt source i ++ ": " ++ case graph IM.! ref (single i) of
          Invalid message -> message
          _ -> "recursive type/join has no well-formed solution preserving every participant")
    emit End = HEnd
    emit (Selection ds) = HSel [[Output r l s w (TypeRef k) | Out r l s w k <- d] | d <- ds]
    emit (InputHead _ bs) = HBra
      [(r,l,s,TypeRef k) | Input r l s k guard <- bs, enabled relation guard]
    emit (Invalid _) = HEnd -- unreachable: invalid nodes have no live diagonal
