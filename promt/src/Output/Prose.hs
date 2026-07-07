{-# LANGUAGE LambdaCase #-}

-- | Exporter to the \"Prose\" surface syntax, the input format of the Prose
-- composition checker (which builds an LTS and discharges deadlock-freedom /
-- liveness via PRISM). 

module Output.Prose
  ( proseType
  , proseProgram
  , proseProgramTypes
  ) where

import Data.List       (intercalate)
import Data.Ratio      (Ratio, numerator, denominator)
import Syntax.Process  (Role(..), Label(..), Sort(..), Proc)
import Typing.Types
import Typing.Infer    (infer)
import Normalize.Passes (normalizeE)

-- | Render one local type in Prose syntax
proseType :: SType -> Either String String
proseType = go [] 0

-- | Render a program: each process is normalized, inferred, and printed as
-- @name : type@. Inference or rendering failure aborts with the message.
proseProgram :: [(String, Proc String)] -> Either String String
proseProgram parts = proseProgramTypes <$> mapM elab parts
  where elab (name, p) = (,) name <$> (normalizeE p >>= infer >>= \t -> t `seq` Right t)

-- | Render already-inferred types as a Prose program.
proseProgramTypes :: [(String, SType)] -> String
proseProgramTypes = intercalate "\n\n" . map render
  where render (name, t) = name ++ " : " ++ either ("<error: " ++) id (proseType t)

-- ---------------------------------------------------------------------------

go :: [String] -> Int -> SType -> Either String String
go env n = \case
  TEnd -> Right "end"

  TRecVar k
    | k >= 0 && k < length env -> Right (env !! k)
    | otherwise -> Left ("Prose: unbound recursion variable (de Bruijn " ++ show k ++ ")")

  TMu (STScope b) ->
    let v = nameAt (length env)
    in (("mu " ++ v ++ ". ") ++) <$> go (v : env) n b

  TBra brs -> do
    parts <- mapM (braBranch env n) brs
    Right (block "&" n parts)

  TSel ds -> do
    blocks <- mapM (oneDist env n) ds
    case blocks of
      [b] -> Right b
      _   -> Right (intercalate ("\n" ++ indent n ++ "+ ") blocks)

oneDist :: [String] -> Int -> Dist -> Either String String
oneDist env n d = do
  parts <- mapM (selBranch env n) d
  Right (block "(+)" n parts)

braBranch :: [String] -> Int -> (Role, Label, Sort, SType) -> Either String String
braBranch env n (r, l, s, t) = do
  c <- go env (n + 1) t
  Right (role r ++ " ? " ++ lab l ++ recvSort s ++ " . " ++ c)

selBranch :: [String] -> Int -> SBranch -> Either String String
selBranch env n (SBranch r w l s t) = do
  c <- go env (n + 1) t
  Right (role r ++ " ! " ++ showWeight w ++ " : " ++ lab l ++ sendSort s ++ " . " ++ c)

-- | A bracketed, indented block of comma-separated branches.
block :: String -> Int -> [String] -> String
block op n parts =
  op ++ " {\n"
     ++ intercalate ",\n" [ indent (n + 1) ++ p | p <- parts ]
     ++ "\n" ++ indent n ++ "}"

indent :: Int -> String
indent n = replicate (2 * n) ' '

-- | Recursion-binder names by depth: t, s, u, v, w, x, y, z, then t8, t9, ...
nameAt :: Int -> String
nameAt i
  | i < length base = base !! i
  | otherwise       = "t" ++ show i
  where base = ["t", "s", "u", "v", "w", "x", "y", "z"]

role :: Role -> String
role (Role r) = r

lab :: Label -> String
lab (Label l) = l

recvSort :: Sort -> String
recvSort SUnit = ""
recvSort s     = "(" ++ sortName s ++ ")"

sendSort :: Sort -> String
sendSort SUnit = ""
sendSort s     = "<" ++ sortName s ++ ">"

sortName :: Sort -> String
sortName = drop 1 . show 

showWeight :: Ratio Integer -> String
showWeight r
  | d == 1    = show nu ++ ".0"
  | otherwise =
      case [ k | k <- [1 .. 24], (10 ^ k) `mod` d == 0 ] of
        (k : _) -> placePoint (nu * (10 ^ k `div` d)) k
        []      -> show nu ++ "/" ++ show d
  where
    nu = numerator r
    d  = denominator r
    placePoint v k =
      let s  = show v
          s' = replicate (max 0 (k + 1 - length s)) '0' ++ s
          (i, f) = splitAt (length s' - k) s'
      in i ++ "." ++ f