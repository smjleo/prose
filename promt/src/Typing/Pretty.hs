{-# LANGUAGE LambdaCase #-}

module Typing.Pretty (pretty) where

import Data.List (intercalate)
import Data.Ratio (numerator, denominator)
import Syntax.Process (Role(..), Label(..), Sort(..))
import Typing.Types

pretty :: SType -> String
pretty = go (names 0)
  where
    names d = take d (map (\n -> "t" ++ show n) [(0::Int)..])

    go _  TEnd          = "end"
    go env (TRecVar k)  = if k < length env then env !! k else "t?" ++ show k
    go env (TMu (STScope b)) =
      let v = "t" ++ show (length env)
      in "mu " ++ v ++ ". " ++ go (v : env) b
    go env (TBra bs)    =
      "&{" ++ intercalate " + "
        [ role r ++ "?" ++ lab l ++ srt s ++ "." ++ go env t | (r,l,s,t) <- bs ] ++ "}"
    go env (TSel ds)    =
      case ds of
        [d] -> dist env d
        _   -> "S{" ++ intercalate " (+) " (map (dist env) ds) ++ "}"

    dist env brs = "(+){" ++ intercalate ", "
      [ role r ++ "!" ++ w wt ++ ":" ++ lab l ++ srt s ++ "." ++ go env t
      | SBranch r wt l s t <- brs ] ++ "}"

    role (Role r)  = r
    lab  (Label l) = l
    srt SUnit = ""
    srt s     = "<" ++ drop 1 (show s) ++ ">"      -- SNat -> <Nat>
    w q = show (numerator q) ++ "/" ++ show (denominator q)
