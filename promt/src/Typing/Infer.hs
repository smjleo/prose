{-# LANGUAGE LambdaCase #-}

-- | Type inference for NORMALIZED processes.
--
-- Normalization is what makes this (mostly) syntax-directed:
--   Every @flip@ now has a NON-RECURSIVE merge

module Typing.Infer
  ( Env
  , infer
  , inferIn
  , inferStrict
  , sortOf
  , mergeFlip
  , mergeFlipStrict
  , joinIf
  ) where

import           Data.List (sortOn)
import           Data.Ratio ((%))
import           Syntax.Process
import           Typing.Types

-- | Sort environment: bound value-variable names to their sorts.
type Env = [(String, Sort)]

-- | Sort of a payload expression under an environment.
sortOf :: Env -> Expr -> Either String Sort
sortOf env = \case
  EUnit            -> Right SUnit
  EBool _          -> Right SBool
  ENat _           -> Right SNat
  EInt _           -> Right SInt
  EVar x           -> case lookup x env of
                        Just s  -> Right s
                        Nothing -> Left ("unbound value variable " ++ show x)
  EFlipChoice _ a b -> do sa <- sortOf env a; sb <- sortOf env b
                          if sa == sb then Right sa
                          else Left "flip-choice payload: branch sorts differ"
  ECond c a b      -> do sc <- sortOf env c
                         if sc /= SBool then Left "if-choice guard is not bool" else do
                           sa <- sortOf env a; sb <- sortOf env b
                           if sa == sb then Right sa
                           else Left "if-choice payload: branch sorts differ"

-- | Keys identifying a send branch within a distribution.
key :: SBranch -> (Role, Label)
key b = (sbRole b, sbLabel b)

-- | True if any element repeats (used to reject ill-formed branchings).
hasDup :: Eq a => [a] -> Bool
hasDup []       = False
hasDup (x : xs) = x `elem` xs || hasDup xs

mergeFlip :: Prob -> SType -> SType -> Either String SType
mergeFlip pr = mergeTypes (probValue pr)

mergeFlipStrict :: Prob -> SType -> SType -> Either String SType
mergeFlipStrict = mergeFlip

-- | [T-FLIP] @T1 merge_p T2@.
mergeTypes :: Weight -> SType -> SType -> Either String SType
mergeTypes p t1 t2
  | p == 0 = Right t2
  | p == 1 = Right t1
mergeTypes _ TEnd TEnd          = Right TEnd
mergeTypes p (TSel dss) (TSel dts) =
  TSel <$> sequence [ mergeDist p di dk | di <- dss, dk <- dts ]
mergeTypes _ (TSel _) (TBra _)  = Left mixedChoiceErr
mergeTypes _ (TBra _) (TSel _)  = Left mixedChoiceErr
mergeTypes _ (TSel _) TEnd      = Left probTermErr
mergeTypes _ TEnd (TSel _)      = Left probTermErr
mergeTypes _ (TBra _) (TBra _)  = Left disjointBraErr
mergeTypes _ t1 t2 =
  Left ("flip cannot merge these types: " ++ show t1 ++ " with " ++ show t2)

mixedChoiceErr, probTermErr, disjointBraErr :: String
mixedChoiceErr =
  "flip mixes a selection (!) and a branching (?): a mixed choice after a flip "
  ++ "is not well-formed"
probTermErr =
  "flip mixes a selection (!) with termination (end): probabilistic termination "
  ++ "is not supported"
disjointBraErr =
  "flip over branchings (?) with disjoint label sets: the merged external choice "
  ++ "would be empty, which is not a well-formed branching"

-- | DISJOINT [M-SEL] on two distributions under weight @p@
mergeDist :: Weight -> Dist -> Dist -> Either String Dist
mergeDist p d1 d2
  | not (null overlapping) =
      Left ("flip requires merging overlapping (non-disjoint) labels "
            ++ show overlapping ++ ": rejected, since a sound merge of the "
            ++ "overlapping continuations is not guaranteed. Normalize first "
            ++ "(distribution / label-factoring) so the flip is over disjoint labels.")
  | otherwise =
      let onlyL = [ b { sbWeight = p       * sbWeight b } | b <- d1 ]
          onlyR = [ b { sbWeight = (1 - p) * sbWeight b } | b <- d2 ]
      in Right (normDist (onlyL ++ onlyR))
  where
    k2          = map key d2
    overlapping = [ key b | b <- d1, key b `elem` k2 ]

-- | [T-COND] via the disjoint [SUB-Sum]: nondeterministic union of distributions. LUB
joinIf :: SType -> SType -> Either String SType
joinIf (TSel ds1) (TSel ds2) = Right (TSel (ds1 ++ ds2))
joinIf TEnd TEnd             = Right TEnd
joinIf (TBra bs1) (TBra bs2) =
  case [ (r, l, so, c1, c2)
       | (r, l, so, c1) <- bs1, (r2, l2, _, c2) <- bs2, r2 == r, l2 == l ] of
    [] -> Left ("if join: branchings share no label (disjoint external choices, "
                ++ "no safe common branch): "
                ++ show [ (r, l) | (r, l, _, _) <- bs1 ] ++ " vs "
                ++ show [ (r, l) | (r, l, _, _) <- bs2 ])
    ms -> do bs <- mapM (\(r, l, so, c1, c2) -> (\c -> (r, l, so, c)) <$> joinIf c1 c2) ms
             Right (TBra bs)
joinIf t1 t2 =
  Left ("if join unsupported for these shapes (needs subtyping join): "
        ++ show t1 ++ "  join  " ++ show t2)

-- | Infer the local type of a normalized process (closed: empty environment).
infer :: Proc String -> Either String SType
infer = inferIn []

-- | Disjoint-only inference: succeeds iff no flip needs an overlapping [M-SEL].
inferStrict :: Proc String -> Either String SType
inferStrict = inferInG mergeFlipStrict []

-- | Infer under a sort environment for received value variables.
inferIn :: Env -> Proc String -> Either String SType
inferIn = inferInG mergeFlip

-- | Inference generic in the flip-merge strategy.
inferInG :: (Prob -> SType -> SType -> Either String SType)
         -> Env -> Proc String -> Either String SType
inferInG mg env = \case
  Nil          -> Right TEnd

  Var (BVar k) -> Right (TRecVar k)
  Var (FVar x) -> Left ("open process variable " ++ show x)

  Sel r l e k  -> do s <- sortOf env e
                     t <- inferInG mg env k
                     Right (TSel [[SBranch r (1 % 1) l s t]])

  Flip pr p q  -> do t1 <- inferInG mg env p
                     t2 <- inferInG mg env q
                     mg pr t1 t2

  If c p q     -> do sc <- sortOf env c
                     if sc /= SBool then Left "if guard is not bool" else do
                       t1 <- inferInG mg env p
                       t2 <- inferInG mg env q
                       joinIf t1 t2

  Mu (Scope b) -> do t <- inferInG mg env b
                     Right (TMu (STScope t))

  Ghost os p   -> do mapM_ (checkObligationG mg env) os
                     inferInG mg env p

  -- each branch binds its value variable (at the annotated sort) in its cont
  Bra bs       -> do let keys = [ (r, l) | (r, l, _, _, _) <- bs ]
                     if hasDup keys
                       then Left ("branching has duplicate (role,label) branches "
                                  ++ "(not a well-formed external choice): " ++ show keys)
                       else do
                         bs' <- mapM (\(r, l, so, vx, k) ->
                                       do t <- inferInG mg ((vx, so) : env) k
                                          Right (r, l, so, t)) bs
                         Right (TBra bs')

checkObligationG :: (Prob -> SType -> SType -> Either String SType)
                 -> Env -> Obligation String -> Either String ()
checkObligationG mg env = \case
  BoolCheck c -> do s <- sortOf env c
                    if s == SBool then Right () else Left "ghost BoolCheck: not bool"
  TypeCheck q -> inferInG mg env q >> Right ()

-- | Canonical branch order within a distribution, so structural equality of
-- inferred types is order-insensitive.
normDist :: Dist -> Dist
normDist = sortOn key