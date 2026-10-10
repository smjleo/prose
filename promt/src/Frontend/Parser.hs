{-# LANGUAGE LambdaCase #-}

module Frontend.Parser (parseDecls, parseContext, Decl(..)) where

import Data.Char     (isSpace, isDigit, isAlpha, isAlphaNum, isAscii)
import Data.List     (elemIndex)
import Data.Ratio    (Ratio, (%))
import qualified Data.Set as Set
import Syntax.Process
import Syntax.Binder  (abstract)
import Typing.Types   (SType(..), SBranch(..), Dist, STScope(..))
import Typing.Relations (validateType)

data Token = TId String | TNum String | TSym Char
  deriving (Eq, Show)

lexTokens :: String -> Either String [Token]
lexTokens [] = Right []
lexTokens ('(' : '*' : cs) = skipComment cs
lexTokens (c : cs)
  | isSpace c                = lexTokens cs
  | isAscii c && (isAlpha c || c == '_') =
                               let (w, r) = span (\x -> isAscii x && (isAlphaNum x || x == '_')) (c : cs)
                               in (TId w :)  <$> lexTokens r
  | isDigit c                = let (n, r) = spanNumber (c : cs)
                               in (TNum n :) <$> lexTokens r
  | c `elem` "!?.<>(){} ,+=:&" = (TSym c :)  <$> lexTokens cs
  | otherwise                = Left ("lex error near: " ++ take 12 (c : cs))

skipComment :: String -> Either String [Token]
skipComment ('*' : ')' : cs) = lexTokens cs
skipComment (_ : cs)         = skipComment cs
skipComment []               = Left "unterminated (* comment"

spanNumber :: String -> (String, String)
spanNumber s =
  let (i, r1) = span isDigit s
  in case r1 of
       ('.' : d : r2) | isDigit d -> let (f, r3) = span isDigit (d : r2) in (i ++ "." ++ f, r3)
       ('/' : d : r2) | isDigit d -> let (f, r3) = span isDigit (d : r2) in (i ++ "/" ++ f, r3)
       _ -> (i, r1)

type R a = Either String (a, [Token])

reserved :: [String]
reserved = [ "flip", "if", "then", "else", "mu", "end", "true", "false"
           , "not", "or", "and", "succ", "neg" ]

data Decl
  = Def  String (Proc String)
  | Spec String SType
  deriving (Eq, Show)

parseDecls :: String -> Either String [Decl]
parseDecls src = do
  toks <- lexTokens src
  decls toks
  where
    decls [] = Right []
    decls ts = do (d, ts') <- decl ts; (d :) <$> decls ts'
    decl (TId name : TSym '=' : ts)
      | name `notElem` reserved && name `notElem` typeReserved =
          do (p, ts') <- pProc ts; Right (Def name p, ts')
    decl (TId name : TSym ':' : ts)
      | name `notElem` typeReserved = do
          (t, ts') <- pType [] ts
          validateType t
          Right (Spec name t, ts')
    decl ts = Left ("expected a 'name = process' or 'name : type' declaration near: "
                    ++ showToks ts)

parseContext :: String -> Either String [(String, SType)]
parseContext src = do
  toks <- lexTokens src
  case toks of
    [] -> Left "a type context must contain at least one participant"
    _ -> context Set.empty toks
  where
    context _ [] = Right []
    context seen ts = do
      (name, r0) <- typeIdent ts
      r1 <- sym ':' r0
      if name `Set.member` seen
        then Left ("duplicate participant " ++ show name)
        else do
          (t, r2) <- pType [] r1
          validateType t
          ((name, t) :) <$> context (Set.insert name seen) r2

-- Only receives can form a '+' branching.
pProc :: [Token] -> R (Proc String)
pProc ts = do
  (t1, r1) <- pTerm ts
  go [t1] r1
  where
    go acc (TSym '+' : rest) = do (t, r) <- pTerm rest; go (t : acc) r
    go [single] rest = Right (single, rest)
    go many rest = do
      bss <- mapM asBranches (reverse many)
      Right (Bra (concat bss), rest)
    asBranches (Bra bs) = Right bs
    asBranches _        = Left "'+' may only join receive (?) branches"

pTerm :: [Token] -> R (Proc String)
pTerm = \case
  (TId "flip" : ts)  -> pFlip ts
  (TId "if"   : ts)  -> pIf ts
  (TId "mu"   : ts)  -> pMu ts
  (TId "end"  : ts)  -> Right (Nil, ts)
  (TNum "0"   : ts)  -> Right (Nil, ts)
  (TSym '('   : ts)  -> do (p, r) <- pProc ts; r' <- sym ')' r; Right (p, r')
  (TSym '{'   : ts)  -> do (p, r) <- pProc ts; r' <- sym '}' r; Right (p, r')
  (TId x : TSym '!' : ts) | x `notElem` reserved -> pSend x ts
  (TId x : TSym '?' : ts) | x `notElem` reserved -> pRecv x ts
  (TId x : ts)
    | x `notElem` reserved -> Right (Var (FVar x), ts)
    | otherwise            -> Left ("unexpected keyword '" ++ x ++ "'")
  ts -> Left ("expected a process near: " ++ showToks ts)

pSend :: String -> [Token] -> R (Proc String)
pSend r ts = do
  (l, t1)  <- ident ts
  (e, t2)  <- sendPayload t1
  t3       <- sym '.' t2
  (k, t4)  <- pTerm t3
  Right (Sel (Role r) (Label l) e k, t4)

pRecv :: String -> [Token] -> R (Proc String)
pRecv r ts = do
  (l, t1)         <- ident ts
  (vx, so, t2)    <- recvPayload t1
  t3              <- sym '.' t2
  (k, t4)         <- pTerm t3
  Right (Bra [(Role r, Label l, so, vx, k)], t4)

pFlip :: [Token] -> R (Proc String)
pFlip ts = do
  (pr, t1) <- probLit ts
  t2       <- sym '(' t1
  (a, t3)  <- pProc t2
  t4       <- sym ',' t3
  (b, t5)  <- pProc t4
  t6       <- sym ')' t5
  prob     <- mkProb pr
  Right (Flip prob a b, t6)

pIf :: [Token] -> R (Proc String)
pIf ts = do
  (e, t1) <- pExpr ts
  t2      <- kw "then" t1
  (a, t3) <- pProc t2
  t4      <- kw "else" t3
  (b, t5) <- pProc t4
  Right (If e a b, t5)

pMu :: [Token] -> R (Proc String)
pMu ts = do
  (x, t1) <- ident ts
  t2      <- sym '.' t1
  (b, t3) <- pProc t2
  Right (Mu (abstract x b), t3)

sendPayload :: [Token] -> R Expr
sendPayload (TSym '<' : ts) = do (e, t1) <- pExpr ts; t2 <- sym '>' t1; Right (e, t2)
sendPayload ts              = Right (EUnit, ts)

recvPayload :: [Token] -> Either String (String, Sort, [Token])
recvPayload (TSym '(' : ts) = do
  (x, t1)  <- ident ts
  t2       <- sym ':' t1
  (so, t3) <- pSort t2
  t4       <- sym ')' t3
  Right (x, so, t4)
recvPayload ts = Right ("_", SUnit, ts)

pExpr :: [Token] -> R Expr
pExpr = pOr
  where
    pOr ts = do
      (l, t1) <- pAnd ts
      case t1 of
        (TId "or" : t2) -> do (r, t3) <- pOr t2; Right (EOr l r, t3)
        _               -> Right (l, t1)
    pAnd ts = do
      (l, t1) <- pCmp ts
      case t1 of
        (TId "and" : t2) -> do (r, t3) <- pAnd t2; Right (EAnd l r, t3)
        _                -> Right (l, t1)
    pCmp ts = do
      (l, t1) <- pAdd ts
      let cmp mk t2 = case pAdd t2 of
            Right (r, t3) -> Right (mk l r, t3)
            Left _        -> Right (l, t1)
      case t1 of
        (TSym '=' : TSym '=' : t2) -> cmp EEq t2
        (TSym '=' : t2)            -> cmp EEq t2
        (TSym '>' : t2)            -> cmp EGt t2
        (TSym '<' : t2)            -> cmp ELt t2
        _                          -> Right (l, t1)
    pAdd ts = do
      (l, t1) <- pAtom ts
      case t1 of
        (TSym '+' : t2) -> do (r, t3) <- pAdd t2; Right (EAdd l r, t3)
        _               -> Right (l, t1)
    pAtom (TId "not" : ts)  = do (e, t1) <- pAtom ts; Right (ENot e, t1)
    pAtom (TId "succ" : TSym '(' : ts) =
      do (e, t1) <- pExpr ts; t2 <- sym ')' t1; Right (ESucc e, t2)
    pAtom (TId "neg" : TSym '(' : ts) =
      do (e, t1) <- pExpr ts; t2 <- sym ')' t1; Right (ENeg e, t2)
    pAtom (TNum n : ts)
      | all isDigit n       = Right (EInt (read n), ts)
    pAtom (TId "true"  : ts) = Right (EBool True,  ts)
    pAtom (TId "false" : ts) = Right (EBool False, ts)
    pAtom (TSym '(' : TSym ')' : ts) = Right (EUnit, ts)
    pAtom (TSym '(' : ts)   = do (e, t1) <- pExpr ts; t2 <- sym ')' t1; Right (e, t2)
    pAtom (TId x : ts) | x `notElem` reserved = Right (EVar x, ts)
    pAtom ts = Left ("expected an expression near: " ++ showToks ts)

pSort :: [Token] -> R Sort
pSort (TId "Unit" : ts) = Right (SUnit, ts)
pSort (TId "Bool" : ts) = Right (SBool, ts)
pSort (TId "Nat"  : ts) = Right (SNat,  ts)
pSort (TId "Int"  : ts) = Right (SInt,  ts)
pSort (TId "Str"  : ts) = Right (SStr,  ts)
pSort ts = Left ("expected a sort (Unit|Bool|Nat|Int|Str) near: " ++ showToks ts)

-- Innermost recursion binder first.
pType :: [String] -> [Token] -> R SType
pType env ts = case ts of
  (TId "end" : r) -> Right (TEnd, r)
  (TId "mu"  : r) -> do (v, r1)  <- typeIdent r
                        r2       <- sym '.' r1
                        (b, r3)  <- pType (v : env) r2
                        Right (TMu (STScope b), r3)
  (TSym '&'  : r) -> do r1        <- sym '{' r
                        (brs, r2) <- sepBy1 ',' (pBraBranch env) r1
                        r3        <- sym '}' r2
                        Right (TBra brs, r3)
  -- '(+)' starts a selection; other parentheses group types.
  (TSym '(' : TSym '+' : TSym ')' : _) -> pSelSum env ts
  (TSym '(' : r) -> do (t, r1) <- pType env r
                       r2      <- sym ')' r1
                       Right (t, r2)
  (TId v     : r)
    | v `notElem` typeReserved -> case elemIndex v env of
        Just i  -> Right (TRecVar i, r)
        Nothing -> Left ("type: unbound recursion variable " ++ show v)
  _ -> Left ("expected a type (end | recvar | mu | & | (+)) near: " ++ showToks ts)

pSelSum :: [String] -> [Token] -> R SType
pSelSum env ts = do
  (d, r) <- pDist env ts
  go [d] r
  where
    go acc (TSym '+' : r) = do (d, r') <- pDist env r; go (d : acc) r'
    go acc r              = Right (TSel (reverse acc), r)

pDist :: [String] -> [Token] -> R Dist
pDist env ts = do
  r0 <- sym '(' ts
  r1 <- sym '+' r0
  r2 <- sym ')' r1
  r3 <- sym '{' r2
  (bs, r4) <- sepBy1 ',' (pSelBranch env) r3
  r5 <- sym '}' r4
  Right (bs, r5)

pSelBranch :: [String] -> [Token] -> R SBranch
pSelBranch env ts = do
  (rn, r0)   <- typeIdent ts
  r1         <- sym '!' r0
  (w, r2)    <- probLit r1
  r3         <- sym ':' r2
  (ln, r4)   <- typeIdent r3
  (so, r5)   <- pSendSort r4
  r6         <- sym '.' r5
  (cont, r7) <- pType env r6
  Right (SBranch (Role rn) w (Label ln) so cont, r7)

pBraBranch :: [String] -> [Token] -> R (Role, Label, Sort, SType)
pBraBranch env ts = do
  (rn, r0)   <- typeIdent ts
  r1         <- sym '?' r0
  (ln, r2)   <- typeIdent r1
  (so, r3)   <- pRecvSort r2
  r4         <- sym '.' r3
  (cont, r5) <- pType env r4
  Right ((Role rn, Label ln, so, cont), r5)

pSendSort :: [Token] -> R Sort
pSendSort (TSym '<' : r) = do (s, r1) <- pSort r; r2 <- sym '>' r1; Right (s, r2)
pSendSort ts             = Right (SUnit, ts)

pRecvSort :: [Token] -> R Sort
pRecvSort (TSym '(' : r) = do (s, r1) <- pSort r; r2 <- sym ')' r1; Right (s, r2)
pRecvSort ts             = Right (SUnit, ts)

sepBy1 :: Char -> ([Token] -> R a) -> [Token] -> R [a]
sepBy1 c p ts = do
  (x, r) <- p ts
  go [x] r
  where
    go acc (TSym d : r) | d == c = do (x, r') <- p r; go (x : acc) r'
    go acc r                     = Right (reverse acc, r)

probLit :: [Token] -> R (Ratio Integer)
probLit (TNum s : ts)
  | '/' `elem` s = let (a, b) = break (== '/') s
                       denominator = read (drop 1 b)
                   in if denominator == 0
                        then Left "probability denominator must be nonzero"
                        else Right (read a % denominator, ts)
  | '.' `elem` s = let (a, b) = break (== '.') s
                       frac   = drop 1 b
                   in Right (read (a ++ frac) % (10 ^ length frac), ts)
  | otherwise    = Right (read s % 1, ts)
probLit ts = Left ("expected a probability near: " ++ showToks ts)

ident :: [Token] -> R String
ident (TId x : ts) | x `notElem` reserved = Right (x, ts)
ident ts = Left ("expected an identifier near: " ++ showToks ts)

typeReserved :: [String]
typeReserved = ["end", "mu", "Int", "Str", "Bool"]

typeIdent :: [Token] -> R String
typeIdent (TId x : ts) | x `notElem` typeReserved = Right (x, ts)
typeIdent ts = Left ("expected a type-context identifier near: " ++ showToks ts)

sym :: Char -> [Token] -> Either String [Token]
sym c (TSym d : ts) | c == d = Right ts
sym c ts = Left ("expected '" ++ [c] ++ "' near: " ++ showToks ts)

kw :: String -> [Token] -> Either String [Token]
kw w (TId x : ts) | x == w = Right ts
kw w ts = Left ("expected '" ++ w ++ "' near: " ++ showToks ts)

showToks :: [Token] -> String
showToks = unwords . map render . take 6
  where
    render (TId x)  = x
    render (TNum n) = n
    render (TSym c) = [c]
