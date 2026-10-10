-- Original source sites, lexical recursion edges and checked expression sorts.
module Typing.Inference.Source
  ( Source(..), SourceNode(..), prepareSource, originAt
  ) where

import qualified Data.IntMap.Strict as IntMap
import qualified Data.Set as Set
import Syntax.Process
import Syntax.WellFormed (checkContractive)
import Typing.Expressions (Env, sortOf)

data SourceNode
  = AEnd
  | ASend Role Label Expr Sort Int
  | AReceive [(Role, Label, Sort, String, Int)]
  | AIf Expr Int Int
  | AFlip Prob Int Int
  | AMu Int
  | AVar Int
  deriving (Eq, Show)

data Source = Source
  { sourceRoot :: Int
  , sourceNodes :: IntMap.IntMap SourceNode
  , sourceOrigins :: IntMap.IntMap String
  } deriving (Eq, Show)

originAt :: Source -> Int -> String
originAt source site =
  IntMap.findWithDefault ("source site " ++ show site) site (sourceOrigins source)

data BuildState = BuildState Int (IntMap.IntMap SourceNode)
                                  (IntMap.IntMap String)
newtype Build a = Build
  { runBuild :: BuildState -> Either String (a, BuildState) }

instance Functor Build where
  fmap f (Build g) = Build $ \s -> do
    (a,s') <- g s
    pure (f a,s')
instance Applicative Build where
  pure a = Build $ \s -> Right (a,s)
  Build f <*> Build g = Build $ \s -> do
    (h,s1) <- f s
    (a,s2) <- g s1
    pure (h a,s2)
instance Monad Build where
  Build g >>= k = Build $ \s -> do
    (a,s1) <- g s
    runBuild (k a) s1

reserve :: Build Int
reserve = Build $ \(BuildState next nodes origins) ->
  Right (next,BuildState (next + 1) nodes origins)

record :: Int -> String -> SourceNode -> Build ()
record site origin node = Build $ \(BuildState next nodes origins) ->
  Right ((),BuildState next (IntMap.insert site node nodes)
                            (IntMap.insert site origin origins))

checked :: String -> Either String a -> Build a
checked origin result = Build $ \s -> case result of
  Left err -> Left (origin ++ ": " ++ err)
  Right a -> Right (a,s)

-- Check all original scopes; resolve recursion indices to lexical binder IDs.
prepareSource :: Proc String -> Either String Source
prepareSource process = do
  checkContractive process
  (root,BuildState _ nodes origins) <-
    runBuild (build [] [] "root" process)
             (BuildState 0 IntMap.empty IntMap.empty)
  pure (Source root nodes origins)
  where
    build :: [Int] -> Env -> String -> Proc String -> Build Int
    build recursion values origin process' = do
      site <- reserve
      node <- case process' of
        Nil -> pure AEnd
        Var (FVar name) -> checked origin
          (Left ("open process variable " ++ show name))
        Var (BVar index) ->
          case if index < 0 then Nothing else atIndex index recursion of
            Nothing -> checked origin
              (Left ("out-of-scope process recursion index " ++ show index))
            Just binder -> pure (AVar binder)
        Mu (Scope body) ->
          AMu <$> build (site : recursion) values (origin ++ "/mu") body
        Sel role label expression continuation -> do
          sort <- checked origin (sortOf values expression)
          child <- build recursion values (origin ++ "/send " ++ key role label)
                         continuation
          pure (ASend role label expression sort child)
        Bra branches -> do
          let keys = [(role,label) | (role,label,_,_,_) <- branches]
          checked origin $ if null branches
            then Left "branching must contain at least one branch"
            else if Set.size (Set.fromList keys) /= length keys
              then Left "branching has duplicate (role,label) branches"
              else Right ()
          AReceive <$> mapM (branch recursion values origin) branches
        If condition yes no -> do
          sort <- checked origin (sortOf values condition)
          checked origin $ if sort == SBool then Right ()
                            else Left "if guard is not bool"
          AIf condition <$> build recursion values (origin ++ "/then") yes
                        <*> build recursion values (origin ++ "/else") no
        Flip probability left right ->
          AFlip probability <$> build recursion values (origin ++ "/flip-left") left
                            <*> build recursion values (origin ++ "/flip-right") right
      record site origin node
      pure site

    branch recursion values origin (role,label,sort,name,continuation) = do
      child <- build recursion ((name,sort) : values)
                     (origin ++ "/receive " ++ key role label) continuation
      pure (role,label,sort,name,child)

    key (Role role) (Label label) = role ++ ":" ++ label
    atIndex 0 (x:_) = Just x
    atIndex n (_:xs) = atIndex (n - 1) xs
    atIndex _ [] = Nothing
