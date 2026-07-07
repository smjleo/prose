{-# LANGUAGE ScopedTypeVariables #-}

module Examples.Tricky (tricky) where

import Data.Ratio ((%))
import Syntax.Process

prob :: Rational -> Prob
prob r = case mkProb r of Right p -> p; Left e -> error e

sndL :: String -> String -> Proc a -> Proc a
sndL r l = Sel (Role r) (Label l) EUnit

recvBool :: String -> String -> Proc a -> Branch a
recvBool r l k = (Role r, Label l, SBool, "x", k)

tricky :: Proc String
tricky = Mu (Scope (Bra [ recvBool "p" "l1" (If (EVar "x") thenB elseB) ]))
  where
    thenB =
      Flip (prob (1 % 4))
        (sndL "q" "l1" (Var (BVar 0)))                          -- q!l1.X
        (sndL "q" "l1"                                          -- q!l1.
          (Mu (Scope (Bra [ recvBool "p" "l1"                   -- muX'. p?l1(x).
              (Flip (prob (1 % 2))
                 (sndL "r" "l1" (Var (BVar 1)))                 -- r!l1.X
                 (sndL "r" "l2" (Var (BVar 0))))                -- r!l2.X'
            ]))))
    elseB = sndL "g" "l1" (Var (BVar 0))                        -- g!l1.X
