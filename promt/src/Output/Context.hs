{-# LANGUAGE LambdaCase #-}

module Output.Context (renderType, pretty) where

import Data.Char       (isAscii, isAlpha, isAlphaNum)
import Data.List       (intercalate)
import Data.Ratio      (Ratio, numerator, denominator)
import Syntax.Process  (Role(..), Label(..), Sort(..))
import Typing.Types

renderType :: SType -> Either String String
renderType = go [] 0

pretty :: SType -> String
pretty = either (\err -> "<" ++ err ++ ">") (unwords . words) . renderType

go :: [String] -> Int -> SType -> Either String String
go env n = \case
  TEnd -> Right "end"

  TRecVar k
    | k >= 0 && k < length env -> Right (env !! k)
    | otherwise -> Left ("unbound recursion variable (de Bruijn " ++ show k ++ ")")

  TMu (STScope b) ->
    let v = nameAt (length env)
    in (("mu " ++ v ++ ". ") ++) <$> go (v : env) n b

  TBra brs -> do
    parts <- mapM (braBranch env n) brs
    Right (block "&" n parts)

  TSel ds -> do
    blocks <- mapM (dist env n) ds
    case blocks of
      [b] -> Right b
      _   -> Right (intercalate ("\n" ++ indent n ++ "+ ") blocks)

dist :: [String] -> Int -> Dist -> Either String String
dist env n d = do
  parts <- mapM (selBranch env n) d
  Right (block "(+)" n parts)

braBranch :: [String] -> Int -> (Role, Label, Sort, SType) -> Either String String
braBranch env n (r, l, s, t) = do
  rn <- identifier (role r)
  ln <- identifier (lab l)
  c <- go env (n + 1) t
  Right (rn ++ " ? " ++ ln ++ recvSort s ++ " . " ++ c)

selBranch :: [String] -> Int -> SBranch -> Either String String
selBranch env n (SBranch r w l s t) = do
  rn <- identifier (role r)
  ln <- identifier (lab l)
  c <- go env (n + 1) t
  Right (rn ++ " ! " ++ weight w ++ " : " ++ ln ++ sendSort s ++ " . " ++ c)

block :: String -> Int -> [String] -> String
block op n parts =
  op ++ " {\n"
     ++ intercalate ",\n" [ indent (n + 1) ++ p | p <- parts ]
     ++ "\n" ++ indent n ++ "}"

indent :: Int -> String
indent n = replicate (2 * n) ' '

nameAt :: Int -> String
nameAt i
  | i < length base = base !! i
  | otherwise       = "t" ++ show i
  where base = ["t", "s", "u", "v", "w", "x", "y", "z"]

role :: Role -> String
role (Role r) = r

lab :: Label -> String
lab (Label l) = l

identifier :: String -> Either String String
identifier name@(c:cs)
  | isAscii c && (isAlpha c || c == '_')
  , all (\x -> isAscii x && (isAlphaNum x || x == '_')) cs
  , name `notElem` ["end", "mu", "Int", "Str", "Bool"] = Right name
identifier name = Left ("invalid type-context identifier " ++ show name)

recvSort :: Sort -> String
recvSort SUnit = ""
recvSort s     = "(" ++ sortName s ++ ")"

sendSort :: Sort -> String
sendSort SUnit = ""
sendSort s     = "<" ++ sortName s ++ ">"

sortName :: Sort -> String
sortName = drop 1 . show

-- Print exact decimals up to 24 places, otherwise fractions.
weight :: Ratio Integer -> String
weight r
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
