{-# LANGUAGE LambdaCase #-}

module Typing.Expressions (Env, sortOf) where

import Syntax.Process

type Env = [(String, Sort)]

sortOf :: Env -> Expr -> Either String Sort
sortOf env = \case
  EUnit            -> Right SUnit
  EBool _          -> Right SBool
  EInt _           -> Right SInt
  EVar x           -> case lookup x env of
                        Just s  -> Right s
                        Nothing -> Left ("unbound value variable " ++ show x)
  ENot a           -> do bool1 "not" a; Right SBool
  EOr a b          -> do bool1 "or" a; bool1 "or" b; Right SBool
  EAnd a b         -> do bool1 "and" a; bool1 "and" b; Right SBool
  EAdd a b         -> numPair "+" a b
  ESucc a          -> do s <- sortOf env a; numeric "succ" s; Right s
  ENeg a           -> do s <- sortOf env a; numeric "neg" s; Right SInt
  EEq a b          -> do sa <- sortOf env a; sb <- sortOf env b
                         if sa == sb || (isNum sa && isNum sb) then Right SBool
                         else Left ("= compares different sorts: "
                                    ++ show sa ++ " vs " ++ show sb)
  EGt a b          -> numPair ">" a b >> Right SBool
  ELt a b          -> numPair "<" a b >> Right SBool
  where
    isNum s = s == SNat || s == SInt
    bool1 op e = do s <- sortOf env e
                    if s == SBool then Right ()
                    else Left (op ++ ": operand is " ++ show s ++ ", not Bool")
    numeric op s = if isNum s then Right ()
                   else Left (op ++ ": operand is " ++ show s ++ ", not numeric")
    numPair op a b = do sa <- sortOf env a; sb <- sortOf env b
                        numeric op sa; numeric op sb
                        Right (if sa == sb then sa else SInt)

