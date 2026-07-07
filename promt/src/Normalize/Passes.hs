{-# LANGUAGE LambdaCase #-}

-- | Normalization driver with guard-aware tying.
--
module Normalize.Passes
  ( normalize
  , normalizeE
  , normalizeWF
  , extractPrefix
  , collapse
  ) where

import           Data.Set (Set)
import qualified Data.Set as Set
import           Data.Ratio          (Ratio)
import           Syntax.Process
import           Syntax.Binder      (instantiate, abstract, unfold)
import           Syntax.RegularTree (regularTreeEq)
import           Syntax.WellFormed  (checkContractive)

-- | Pass 1, send half (flip only): hoist a send shared on the same (role,label)
-- out of a FLIP, combining payloads.
--
braRoles :: [Branch a] -> [Role]
braRoles bs = Set.toAscList (Set.fromList [ r | (r, _, _, _, _) <- bs ])

extractPrefix :: Eq a => Proc a -> Proc a
extractPrefix = \case
  Flip pr (Sel r1 l1 e1 k1) (Sel r2 l2 e2 k2)
    | r1 == r2 && l1 == l2 ->
        let e = if e1 == e2 then e1 else EFlipChoice pr e1 e2
        in Sel r1 l1 e (Flip pr k1 k2)

  -- distribute a flip over an if 
  Flip pr (If c a b) z -> If c (Flip pr a z) (Flip pr b z)
  Flip pr z (If c a b) -> If c (Flip pr z a) (Flip pr z b)

  -- receive half: push a flip over shared branchings into the continuations
  -- (the [M-BRA]-shaped rearrangement). 
  Flip pr (Bra bs1) (Bra bs2)
    | not (null shared) && rolesPreserved ->
        let core = Bra shared
        in if null obs then core else Ghost obs core
    where
      rolesPreserved = braRoles bs1 == braRoles bs2
                       && braRoles shared == braRoles bs1
      shared = [ (r, l, so, vx, k)
               | (r, l, so, vx1, k1) <- bs1
               , (r2, l2, _, vx2, k2) <- bs2, r2 == r, l2 == l
               , let (vx, k) = mergeCont (Flip pr) vx1 k1 vx2 k2 ]
      inB2 r l = any (\(r2,l2,_,_,_) -> r2 == r && l2 == l) bs2
      inB1 r l = any (\(r2,l2,_,_,_) -> r2 == r && l2 == l) bs1
      onlyL = [ b | b@(r,l,_,_,_) <- bs1, not (inB2 r l) ]
      onlyR = [ b | b@(r,l,_,_,_) <- bs2, not (inB1 r l) ]
      obs = [ TypeCheck (Bra onlyL) | not (null onlyL) ]
            ++ [ TypeCheck (Bra onlyR) | not (null onlyR) ]

  -- receive half for `if`: the same [M-BRA] intersection as the flip case, but
  -- the merged continuation is the `if` (not the flip) of the two. 
  If c (Bra bs1) (Bra bs2)
    | not (null shared) && rolesPreserved ->
        let core = Bra shared
        in if null obs then core else Ghost obs core
    where
      rolesPreserved = braRoles bs1 == braRoles bs2
                       && braRoles shared == braRoles bs1
      shared = [ (r, l, so, vx, k)
               | (r, l, so, vx1, k1) <- bs1
               , (r2, l2, _, vx2, k2) <- bs2, r2 == r, l2 == l
               , let (vx, k) = mergeCont (If c) vx1 k1 vx2 k2 ]
      inB2 r l = any (\(r2,l2,_,_,_) -> r2 == r && l2 == l) bs2
      inB1 r l = any (\(r2,l2,_,_,_) -> r2 == r && l2 == l) bs1
      onlyL = [ b | b@(r,l,_,_,_) <- bs1, not (inB2 r l) ]
      onlyR = [ b | b@(r,l,_,_,_) <- bs2, not (inB1 r l) ]
      obs = [ TypeCheck (Bra onlyL) | not (null onlyL) ]
            ++ [ TypeCheck (Bra onlyR) | not (null onlyR) ]

  -- a flip over two selection-distributions
  Flip pr p q
    | Just dp <- asDist (probValue pr) p
    , Just dq <- asDist (1 - probValue pr) q
    , let items = dp ++ dq
    , sharesLabel items
    -> regroup items

  p -> p

-- | Flatten a selection-distribution process
asDist :: Ratio Integer -> Proc a -> Maybe [(Role, Label, Expr, Ratio Integer, Proc a)]
asDist w = \case
  Sel r l e k -> Just [(r, l, e, w, k)]
  Flip pr a b -> let p = probValue pr
                 in (++) <$> asDist (w * p) a <*> asDist (w * (1 - p)) b
  Ghost obs p -> map (push obs) <$> asDist w p
  _           -> Nothing
  where
    push os (r, l, e, wt, k) = (r, l, e, wt, if null os then k else Ghost os k)

-- | Does some @(role,label)@ key occur more than once (i.e. is there an
-- overlap to factor out)?
sharesLabel :: [(Role, Label, Expr, Ratio Integer, Proc a)] -> Bool
sharesLabel items = length (dedupKeys ks) < length ks
  where ks = [ (r, l) | (r, l, _, _, _) <- items ]

dedupKeys :: Eq b => [b] -> [b]
dedupKeys = foldr (\k acc -> if k `elem` acc then acc else k : acc) []

-- | Regroup a flat weighted send-list 
regroup :: [(Role, Label, Expr, Ratio Integer, Proc a)] -> Proc a
regroup items = mkFlipTree [ (groupWeight g, sendOf g) | g <- groups ]
  where
    keys   = dedupKeys [ (r, l) | (r, l, _, _, _) <- items ]
    groups = [ [ it | it@(r, l, _, _, _) <- items, (r, l) == k ] | k <- keys ]
    groupWeight g = sum [ w | (_, _, _, w, _) <- g ]
    sendOf g@((r, l, _, _, _) : _) =
      Sel r l (mkPayload [ (w, e) | (_, _, e, w, _) <- g ])
              (mkFlipTree [ (w, k) | (_, _, _, w, k) <- g ])
    sendOf [] = Nil  -- unreachable: groups are non-empty by construction

mkFlipTree :: [(Ratio Integer, Proc a)] -> Proc a
mkFlipTree []           = Nil
mkFlipTree [(_, k)]     = k
mkFlipTree ((w, k) : r) = Flip (forceProb (w / (w + sum (map fst r)))) k (mkFlipTree r)

-- | Combine the payloads of merged same-label sends into one expression
mkPayload :: [(Ratio Integer, Expr)] -> Expr
mkPayload []            = EUnit
mkPayload [(_, e)]      = e
mkPayload ((w, e) : r)
  | all ((== e) . snd) r = e
  | otherwise            = EFlipChoice (forceProb (w / (w + sum (map fst r)))) e (mkPayload r)

forceProb :: Ratio Integer -> Prob
forceProb = either error id . mkProb

-- | Merge two receive-continuations that share a @(role,label)@ 
mergeCont :: (Proc a -> Proc a -> Proc a)
          -> String -> Proc a -> String -> Proc a -> (String, Proc a)
mergeCont comb vx1 k1 vx2 k2
  | vx1 == vx2 = (vx1, comb k1 k2)
  | otherwise  = let z = freshen vx1 (namesIn k1 ++ namesIn k2)
                 in (z, comb (renameVar vx1 z k1) (renameVar vx2 z k2))

-- | First of @base, base', base'', ...@ not in the avoid list.
freshen :: String -> [String] -> String
freshen base avoid = head [ n | n <- cands, n `notElem` avoid ]
  where cands = base : [ base ++ replicate k '\'' | k <- [1 ..] ]

-- | All value-variable names (bound and free) occurring in a process.
namesIn :: Proc a -> [String]
namesIn = \case
  Nil          -> []
  Sel _ _ e k  -> exprNames e ++ namesIn k
  Bra bs       -> concat [ vx : namesIn k | (_, _, _, vx, k) <- bs ]
  Flip _ a b   -> namesIn a ++ namesIn b
  If c a b     -> exprNames c ++ namesIn a ++ namesIn b
  Mu (Scope k) -> namesIn k
  Var _        -> []
  Ghost os k   -> concatMap obNames os ++ namesIn k
  where
    obNames (BoolCheck e) = exprNames e
    obNames (TypeCheck k) = namesIn k

exprNames :: Expr -> [String]
exprNames = \case
  EVar x            -> [x]
  EFlipChoice _ a b -> exprNames a ++ exprNames b
  ECond a b c       -> exprNames a ++ exprNames b ++ exprNames c
  _                 -> []

-- | Rename a free value variable @from@ to @to@ in a process.
renameVar :: String -> String -> Proc a -> Proc a
renameVar from to = goP
  where
    goP = \case
      Nil          -> Nil
      Sel r l e k  -> Sel r l (goE e) (goP k)
      Bra bs       -> Bra [ if vx == from then (r, l, so, vx, k)       -- shadowed
                                          else (r, l, so, vx, goP k)
                          | (r, l, so, vx, k) <- bs ]
      Flip pr a b  -> Flip pr (goP a) (goP b)
      If c a b     -> If (goE c) (goP a) (goP b)
      Mu (Scope k) -> Mu (Scope (goP k))
      Var v        -> Var v
      Ghost os k   -> Ghost (map goOb os) (goP k)
    goE = \case
      EVar x | x == from -> EVar to
      EFlipChoice p a b  -> EFlipChoice p (goE a) (goE b)
      ECond a b c        -> ECond (goE a) (goE b) (goE c)
      e                  -> e
    goOb (BoolCheck e) = BoolCheck (goE e)
    goOb (TypeCheck k) = TypeCheck (goP k)

collapse :: Ord a => Proc a -> Proc a
collapse = \case
  Flip _ p q | regularTreeEq p q -> p
  If c p q   | regularTreeEq p q -> Ghost [BoolCheck c] p
  p -> p

-- -------------------
-- Fresh-name supply
-- -------------------

newtype NormM a = NormM { unNormM :: Int -> (Either String a, Int) }

instance Functor NormM where
  fmap f (NormM g) = NormM (\s -> let (e, s') = g s in (fmap f e, s'))
instance Applicative NormM where
  pure a = NormM (\s -> (Right a, s))
  NormM f <*> NormM g = NormM (\s ->
    case f s of
      (Left e,  s1) -> (Left e, s1)
      (Right h, s1) -> let (e2, s2) = g s1 in (fmap h e2, s2))
instance Monad NormM where
  NormM g >>= k = NormM (\s ->
    case g s of
      (Left e,  s1) -> (Left e, s1)
      (Right a, s1) -> unNormM (k a) s1)

fresh :: String -> NormM String
fresh base = NormM (\s -> (Right ("#" ++ base ++ show s), s + 1))

-- | Abort normalization: the merge is undefined (divergent / non-regular).
diverge :: String -> NormM a
diverge msg = NormM (\s -> (Left msg, s))

-- ----------
-- Driver
-- ----------

data Ctx  = Bare | Guarded deriving (Eq, Show)
type Defs = [(String, Proc String)]
type Memo = [(Proc String, String)]

-- | Flip goals on the current recursion path:
type Trail = [(Proc String, Proc String, Prob)]

-- | If this flip goal revisits a trail vertex at a different probability, the
-- merge tree is non-regular (Example 3.6): report it.
divergesAt :: Trail -> Prob -> Proc String -> Proc String -> Maybe String
divergesAt trail pr p q =
  case [ r | (a, b, r) <- trail, r /= pr, regularTreeEq a p, regularTreeEq b q ] of
    (r : _) -> Just ("non-cycle-consistent merge: a selection state recurs at "
                     ++ "probabilities " ++ show (probValue r) ++ " and "
                     ++ show (probValue pr)
                     ++ " -- the merge tree is non-regular, so no finite session "
                     ++ "type denotes it (the merge is undefined)")
    []      -> Nothing

findTie :: Memo -> Proc String -> Maybe String
findTie memo goal =
  case [ name | (g, name) <- memo, regularTreeEq g goal ] of
    (name : _) -> Just name
    []         -> Nothing

-- | Defensive backstop only
fuel0 :: Int
fuel0 = 100000

-- | Expose the head of a would-be bare branch by unfolding 
resolve :: Defs -> Set String -> Int -> Proc String -> Proc String
resolve defs vis fuel t
  | fuel <= 0 = t
  | otherwise = case t of
      Var (FVar x)
        | x `Set.notMember` vis
        , Just b <- lookup x defs -> resolve defs (Set.insert x vis) (fuel - 1) b
      Mu _                        -> resolve defs vis (fuel - 1) (unfold t)
      _                           -> t

-- | Unfold while the head is a @mu@ 
whnfMu :: Proc a -> Proc a
whnfMu = go (fuel0 :: Int)
  where
    go n _ | n <= 0 = error "whnfMu: fuel exhausted (non-contractive input?)"
    go n t = case t of
      Mu _      -> go (n - 1) (unfold t)
      Ghost o p -> Ghost o (go n p)
      _         -> t

-- | Normalize a closed source process
normalize :: Proc String -> Proc String
normalize = either error id . normalizeE

-- | Normalize, returning @Left diagnostic@ if a non-cycle-consistent (divergent)
-- merge is encountered instead of looping forever.
normalizeE :: Proc String -> Either String (Proc String)
normalizeE p = fst (unNormM (fmap fst (norm Guarded [] [] [] p)) 0)

-- | Contractivity-checked entry point.
normalizeWF :: Proc String -> Either String (Proc String)
normalizeWF p = checkContractive p >> normalizeE p

norm :: Ctx -> Defs -> Memo -> Trail -> Proc String -> NormM (Proc String, Set String)
norm ctx defs memo trail t = case t of
  Nil          -> pure (Nil, Set.empty)
  Var (FVar x) -> pure (Var (FVar x), Set.singleton x)
  Var v        -> pure (Var v, Set.empty)

  Sel r l e k  -> do (k', u) <- norm Guarded defs memo trail k
                     pure (Sel r l e k', u)

  Bra bs       -> do rs <- mapM (\(r, l, so, vx, k) ->
                                   do (k', u) <- norm Guarded defs memo trail k
                                      pure ((r, l, so, vx, k'), u)) bs
                     pure (Bra (map fst rs), Set.unions (map snd rs))

  Ghost os p   -> do (p', u) <- norm ctx defs memo trail p
                     pure (Ghost os p', u)

  Mu s         -> do x <- fresh "x"
                     let body  = instantiate (Var (FVar x)) s
                         defs' = (x, body) : defs
                     (b', u) <- norm ctx defs' memo trail body
                     if x `Set.member` u
                       then pure (Mu (abstract x b'), Set.delete x u)
                       else pure (b', u)

  Flip pr p q
    | regularTreeEq p q -> norm ctx defs memo trail p
    | otherwise         -> case divergesAt trail pr p q of
        Just msg -> diverge msg
        Nothing  -> processGoal ctx defs memo ((p, q, pr) : trail) t (Flip pr) p q

  If c p q
    | regularTreeEq p q -> do (p', u) <- norm ctx defs memo trail p
                              pure (Ghost [BoolCheck c] p', u)
    | otherwise         -> processGoal ctx defs memo trail t (If c) p q

-- | A flip\/if branch: normalize in 'Bare' context, then clear any mu that would
-- sit directly under the flip.
normBranch :: Defs -> Memo -> Trail -> Proc String -> NormM (Proc String, Set String)
normBranch defs memo trail b = do
  (r, u) <- norm Bare defs memo trail b
  pure (whnfMu r, u)

-- | Process the structure of a goal once: resolve branch heads, extract a shared
-- prefix, recurse (branches in 'Bare'); no registration, no mu-wrapping.
expandGoal
  :: Defs -> Memo -> Trail
  -> (Proc String -> Proc String -> Proc String)
  -> Proc String -> Proc String
  -> NormM (Proc String, Set String)
expandGoal defs memo trail rebuild p q =
  if extracted == original
    then disjointCase                              -- nothing fired: genuinely disjoint flip/if
    else norm Guarded defs memo trail extracted    -- send/branch extracted, or flip distributed over if
  where
    p1        = resolve defs Set.empty fuel0 p
    q1        = resolve defs Set.empty fuel0 q
    original  = rebuild p1 q1
    extracted = extractPrefix original
    disjointCase = do (b1, u1) <- normBranch defs memo trail p1
                      (b2, u2) <- normBranch defs memo trail q1
                      pure (rebuild b1 b2, Set.union u1 u2)

processGoal
  :: Ctx -> Defs -> Memo -> Trail
  -> Proc String                                   -- original goal (memo key)
  -> (Proc String -> Proc String -> Proc String)   -- rebuild from two branches
  -> Proc String -> Proc String
  -> NormM (Proc String, Set String)
processGoal ctx defs memo trail orig rebuild p q =
  case findTie memo orig of
    Just g
      | ctx == Guarded -> pure (Var (FVar g), Set.singleton g)   -- tie the knot
      | otherwise      -> expandGoal defs memo trail rebuild p q  -- bare: expand, reuse g
    Nothing -> do
      g <- fresh "g"
      let memo' = (orig, g) : memo
      (b, u) <- expandGoal defs memo' trail rebuild p q
      if g `Set.member` u
        then pure (Mu (abstract g b), Set.delete g u)
        else pure (b, u)