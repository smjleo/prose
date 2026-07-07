{-# LANGUAGE LambdaCase #-}

-- | A small front-end: parse processes written in an ASCII surface syntax into
-- the 'Proc' AST, so the @promt@ executable can read a file of role bindings.
--
-- > program ::= (role '=' proc)*
-- > proc    ::= '0' | 'end'
-- >           | role '!' label ('<' expr '>')? '.' proc  
-- >           | recv ('+' recv)*                         
-- >           | 'if' expr 'then' proc 'else' proc
-- >           | 'mu' var '.' proc | var                  
-- >           | 'flip' prob '(' proc ',' proc ')'        
-- >           | '(' proc ')' | '{' proc '}'              
-- > recv    ::= role '?' label ('(' var ':' sort ')')? '.' proc
-- > sort    ::= 'Unit' | 'Bool' | 'Nat' | 'Int'
-- > expr    ::= var | integer | 'true' | 'false' | '(' ')'
-- > prob    ::= decimal (0.5) | fraction (1/2) | integer

module Frontend.Parser
  ( parseProgram
  , parseDecls
  , Decl(..)
  , parseProc
  , parseType
  ) where

import Data.Char     (isSpace, isDigit, isAlpha, isAlphaNum)
import Data.List     (elemIndex)
import Data.Ratio    (Ratio, (%))
import Syntax.Process
import Syntax.Binder  (abstract)
import Typing.Types   (SType(..), SBranch(..), Dist, STScope(..))

-- ---------------------------------------------------------------------------
-- Tokens

data Token = TId String | TNum String | TSym Char
  deriving (Eq, Show)

lexTokens :: String -> Either String [Token]
lexTokens [] = Right []
lexTokens ('(' : '*' : cs) = skipComment cs
lexTokens (c : cs)
  | isSpace c                = lexTokens cs
  | isAlpha c || c == '_'    = let (w, r) = span (\x -> isAlphaNum x || x == '_') (c : cs)
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

-- Parser

type R a = Either String (a, [Token])

reserved :: [String]
reserved = ["flip", "if", "then", "else", "mu", "end", "true", "false"]

data Decl
  = Def  String (Proc String)   
  | Spec String SType           
  deriving (Eq, Show)

-- | Parse a whole program: a sequence of @name '=' proc@ and @name ':' type@
-- declarations, in any order.
parseDecls :: String -> Either String [Decl]
parseDecls src = do
  toks <- lexTokens src
  decls toks
  where
    decls [] = Right []
    decls ts = do (d, ts') <- decl ts; (d :) <$> decls ts'
    decl (TId name : TSym '=' : ts)
      | name `notElem` reserved = do (p, ts') <- pProc ts;     Right (Def  name p, ts')
    decl (TId name : TSym ':' : ts)
      | name `notElem` reserved = do (t, ts') <- pType [] ts;  Right (Spec name t, ts')
    decl ts = Left ("expected a 'name = process' or 'name : type' declaration near: "
                    ++ showToks ts)

-- | Parse a whole program, keeping only the process definitions (type specs are
-- dropped).
parseProgram :: String -> Either String [(String, Proc String)]
parseProgram src = do
  ds <- parseDecls src
  Right [ (n, p) | Def n p <- ds ]

-- | Parse a single process (exposed for tests).
parseProc :: String -> Either String (Proc String)
parseProc src = do
  toks <- lexTokens src
  (p, rest) <- pProc toks
  case rest of
    [] -> Right p
    _  -> Left ("trailing tokens: " ++ showToks rest)

-- A process is a '+'-separated list of terms; if more than one, all must be
-- receives and they fuse into a single branching.
pProc :: [Token] -> R (Proc String)
pProc ts = do
  (t1, r1) <- pTerm ts
  go [t1] r1
  where
    go acc (TSym '+' : rest) = do (t, r) <- pTerm rest; go (acc ++ [t]) r
    go [single] rest = Right (single, rest)
    go many rest = do
      bss <- mapM asBranches many
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
  (TSym '{'   : ts)  -> do (p, r) <- pProc ts; r' <- sym '}' r; Right (p, r')   -- grouping
  (TId x : TSym '!' : ts) | x `notElem` reserved -> pSend x ts
  (TId x : TSym '?' : ts) | x `notElem` reserved -> pRecv x ts
  (TId x : ts)
    | x `notElem` reserved -> Right (Var (FVar x), ts)   -- process variable
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
pExpr (TNum n : ts)
  | all isDigit n        = Right (EInt (read n), ts)
pExpr (TId "true"  : ts) = Right (EBool True,  ts)
pExpr (TId "false" : ts) = Right (EBool False, ts)
pExpr (TSym '(' : TSym ')' : ts) = Right (EUnit, ts)
pExpr (TId x : ts) | x `notElem` reserved = Right (EVar x, ts)
pExpr ts = Left ("expected an expression near: " ++ showToks ts)

pSort :: [Token] -> R Sort
pSort (TId "Unit" : ts) = Right (SUnit, ts)
pSort (TId "Bool" : ts) = Right (SBool, ts)
pSort (TId "Nat"  : ts) = Right (SNat,  ts)
pSort (TId "Int"  : ts) = Right (SInt,  ts)
pSort ts = Left ("expected a sort (Unit|Bool|Nat|Int) near: " ++ showToks ts)

-- ---------------------------------------------------------------------------
-- Type parser: the Prose surface syntax for local types -> 'SType'.
--
-- > type    ::= 'end' | recvar | 'mu' var '.' type
-- >           | '&' '{' braB (',' braB)* '}'    
-- >           | dist ('+' dist)*                
-- > dist    ::= '(+)' '{' selB (',' selB)* '}'
-- > braB    ::= role '?' label ('(' Sort ')')? '.' type
-- > selB    ::= role '!' weight ':' label ('<' Sort '>')? '.' type
--

-- | Parse a local type written in Prose syntax.
parseType :: String -> Either String SType
parseType src = do
  toks <- lexTokens src
  (t, rest) <- pType [] toks
  case rest of
    [] -> Right t
    _  -> Left ("trailing tokens in type: " ++ showToks rest)

-- @env@: recursion-binder names with the innermost binder at the head.
pType :: [String] -> [Token] -> R SType
pType env ts = case ts of
  (TId "end" : r) -> Right (TEnd, r)
  (TId "mu"  : r) -> do (v, r1)  <- ident r
                        r2       <- sym '.' r1
                        (b, r3)  <- pType (v : env) r2
                        Right (TMu (STScope b), r3)
  (TSym '&'  : r) -> do r1        <- sym '{' r
                        (brs, r2) <- sepBy1 ',' (pBraBranch env) r1
                        r3        <- sym '}' r2
                        Right (TBra brs, r3)
  (TSym '('  : _) -> pSelSum env ts
  (TId v     : r)
    | v `notElem` reserved -> case elemIndex v env of
        Just i  -> Right (TRecVar i, r)
        Nothing -> Left ("type: unbound recursion variable " ++ show v)
  _ -> Left ("expected a type (end | recvar | mu | & | (+)) near: " ++ showToks ts)

-- A selection is a '+'-separated sum of one or more (+) distribution blocks.
pSelSum :: [String] -> [Token] -> R SType
pSelSum env ts = do
  (d, r) <- pDist env ts
  go [d] r
  where
    go acc (TSym '+' : r) = do (d, r') <- pDist env r; go (acc ++ [d]) r'
    go acc r              = Right (TSel acc, r)

-- One @(+) { selB, ... }@ distribution block.
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
  (rn, r0)   <- ident ts
  r1         <- sym '!' r0
  (w, r2)    <- probLit r1
  r3         <- sym ':' r2
  (ln, r4)   <- ident r3
  (so, r5)   <- pSendSort r4
  r6         <- sym '.' r5
  (cont, r7) <- pType env r6
  Right (SBranch (Role rn) w (Label ln) so cont, r7)

pBraBranch :: [String] -> [Token] -> R (Role, Label, Sort, SType)
pBraBranch env ts = do
  (rn, r0)   <- ident ts
  r1         <- sym '?' r0
  (ln, r2)   <- ident r1
  (so, r3)   <- pRecvSort r2
  r4         <- sym '.' r3
  (cont, r5) <- pType env r4
  Right ((Role rn, Label ln, so, cont), r5)

-- send payloads in angle brackets, receive payloads in parens; bare = Unit.
pSendSort :: [Token] -> R Sort
pSendSort (TSym '<' : r) = do (s, r1) <- pSort r; r2 <- sym '>' r1; Right (s, r2)
pSendSort ts             = Right (SUnit, ts)

pRecvSort :: [Token] -> R Sort
pRecvSort (TSym '(' : r) = do (s, r1) <- pSort r; r2 <- sym ')' r1; Right (s, r2)
pRecvSort ts             = Right (SUnit, ts)

-- | One-or-more @p@ separated by the symbol @c@.
sepBy1 :: Char -> ([Token] -> R a) -> [Token] -> R [a]
sepBy1 c p ts = do
  (x, r) <- p ts
  go [x] r
  where
    go acc (TSym d : r) | d == c = do (x, r') <- p r; go (acc ++ [x]) r'
    go acc r                     = Right (acc, r)

probLit :: [Token] -> R (Ratio Integer)
probLit (TNum s : ts)
  | '/' `elem` s = let (a, b) = break (== '/') s
                   in Right (read a % read (drop 1 b), ts)
  | '.' `elem` s = let (a, b) = break (== '.') s
                       frac   = drop 1 b
                   in Right (read (a ++ frac) % (10 ^ length frac), ts)
  | otherwise    = Right (read s % 1, ts)
probLit ts = Left ("expected a probability near: " ++ showToks ts)

-- token expectations -------------------------------------------------------

ident :: [Token] -> R String
ident (TId x : ts) | x `notElem` reserved = Right (x, ts)
ident ts = Left ("expected an identifier near: " ++ showToks ts)

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