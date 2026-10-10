-- Candidate graphs require independent source validation.
module Typing.Inference.Candidate
  ( TypeRef(..), Output(..), TypeHead(..), Candidate(..)
  , compact, typeGraph, emitType
  ) where

import qualified Data.IntMap.Strict as IntMap
import qualified Data.Map.Strict as Map
import Syntax.Process (Role, Label, Sort)
import qualified Typing.Relations.Graph as Graph
import Typing.Types

newtype TypeRef = TypeRef Int deriving (Eq, Ord, Show)

data Output = Output Role Label Sort Weight TypeRef
  deriving (Eq, Ord, Show)

data TypeHead
  = HEnd
  | HSel [[Output]]
  | HBra [(Role, Label, Sort, TypeRef)]
  deriving (Eq, Ord, Show)

data Candidate = Candidate
  { candidateGraph :: Map.Map TypeRef TypeHead
  , sourceTypes :: IntMap.IntMap TypeRef
  } deriving (Eq, Show)

-- Share equal regular trees, retaining source assignments and summand multiplicity.
compact :: Candidate -> Either String Candidate
compact candidate = do
  mapM_ require (IntMap.elems (sourceTypes candidate))
  (_,colors) <- Graph.compactGraph (typeGraph candidate)
  let rename (TypeRef ref) = TypeRef (colors IntMap.! ref)
  pure Candidate
    { candidateGraph = Map.fromList
        [(rename ref, mapRefs rename node) | (ref,node) <- Map.toAscList graph]
    , sourceTypes = IntMap.map rename (sourceTypes candidate)
    }
  where
    graph = candidateGraph candidate
    require ref = if Map.member ref graph then Right ()
      else Left ("missing candidate type reference " ++ show ref)

typeGraph :: Candidate -> Graph.Graph
typeGraph = IntMap.fromList . map convert . Map.toAscList . candidateGraph
  where
    ref (TypeRef i) = i
    convert (key,node) = (ref key,case node of
      HEnd -> Graph.NEnd
      HSel ds -> Graph.NSel
        [[(r,l,s,w,ref k) | Output r l s w k <- d] | d <- ds]
      HBra bs -> Graph.NBra [(r,l,s,ref k) | (r,l,s,k) <- bs])

mapRefs :: (TypeRef -> TypeRef) -> TypeHead -> TypeHead
mapRefs _ HEnd = HEnd
mapRefs f (HSel ds) = HSel [[Output r l s w (f k) | Output r l s w k <- d] | d <- ds]
mapRefs f (HBra bs) = HBra [(r,l,s,f k) | (r,l,s,k) <- bs]

-- Reserve binders for guarded cycles; remove vacuous binders.
emitType :: Candidate -> TypeRef -> Either String SType
emitType candidate = go []
  where
    go active ref = case index ref active of
      Just k -> Right (TRecVar k)
      Nothing -> do
        node <- maybe (Left ("missing candidate type reference " ++ show ref)) Right
                  (Map.lookup ref (candidateGraph candidate))
        case node of
          HEnd -> Right TEnd
          HSel ds -> bind <$> (TSel <$> mapM (mapM (branch (ref : active))) ds)
          HBra bs -> bind <$> (TBra <$> mapM (input (ref : active)) bs)
    bind body = if uses 0 body then TMu (STScope body) else lower 0 body
    branch env (Output r l s w k) = SBranch r w l s <$> go env k
    input env (r,l,s,k) = (\t -> (r,l,s,t)) <$> go env k
    index _ [] = Nothing
    index x (y:ys) | x == y = Just 0
                   | otherwise = (1 +) <$> index x ys

    uses depth t = case t of
      TEnd -> False
      TRecVar k -> k == depth
      TMu (STScope b) -> uses (depth + 1) b
      TSel ds -> any (uses depth . sbCont) (concat ds)
      TBra bs -> any (\(_,_,_,c) -> uses depth c) bs

    lower depth t = case t of
      TEnd -> TEnd
      TRecVar k -> TRecVar (if k > depth then k - 1 else k)
      TMu (STScope b) -> TMu (STScope (lower (depth + 1) b))
      TSel ds -> TSel [[b { sbCont = lower depth (sbCont b) } | b <- d] | d <- ds]
      TBra bs -> TBra [(r,l,s,lower depth c) | (r,l,s,c) <- bs]
