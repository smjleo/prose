{-# LANGUAGE ScopedTypeVariables #-}


module Examples.DiningPhilosophers
  ( philosopher0
  , fork1
  , waiter
  , half
  ) where

import Data.Ratio ((%))
import Syntax.Process

half :: Prob
half = case mkProb (1 % 2) of Right p -> p; Left e -> error e

-- send a pure label (selection)
sndL :: String -> String -> Proc a -> Proc a
sndL r l = Sel (Role r) (Label l) EUnit

-- a branching alternative: receive a pure label, then continue
br :: String -> String -> Proc a -> Branch a
br r l k = (Role r, Label l, SUnit, "_", k)

x_, y_ :: Proc a
x_ = Var (BVar 1)   -- outer recursion, seen from inside a μY
y_ = Var (BVar 0)   -- inner retry recursion

-- P_0 = μX. flip(1/2){ H ⇒ ... ‖ T ⇒ ... }
philosopher0 :: Proc String
philosopher0 = Mu (Scope (Flip half hBranch tBranch))
  where
    -- H: try left fork f0 first, then right fork f1
    hBranch = Mu (Scope
      (sndL "f0" "pick" (Bra
        [ br "f0" "notFree" y_
        , br "f0" "free"
            (sndL "f1" "pick" (Bra
              [ br "f1" "notFree" (sndL "f0" "drop" x_)
              , br "f1" "free"
                  (sndL "q" "eat" (sndL "f0" "drop" (sndL "f1" "drop" x_)))
              ]))
        ])))
    -- T: try right fork f1 first, then left fork f0 (f0 <-> f1 swapped)
    tBranch = Mu (Scope
      (sndL "f1" "pick" (Bra
        [ br "f1" "notFree" y_
        , br "f1" "free"
            (sndL "f0" "pick" (Bra
              [ br "f0" "notFree" (sndL "f1" "drop" x_)
              , br "f0" "free"
                  (sndL "q" "eat" (sndL "f1" "drop" (sndL "f0" "drop" x_)))
              ]))
        ])))

-- F_1 = μX. ( p1?pick.p1!free.μY.(p1?drop.X + p0?pick.p0!notFree.Y)
--           + p0?pick.p0!free.μY.(p0?drop.X + p1?pick.p1!notFree.Y) )
fork1 :: Proc String
fork1 = Mu (Scope (Bra [branch1, branch2]))
  where
    branch1 = br "p1" "pick"
      (sndL "p1" "free" (Mu (Scope (Bra
        [ br "p1" "drop" x_
        , br "p0" "pick" (sndL "p0" "notFree" y_)
        ]))))
    branch2 = br "p0" "pick"
      (sndL "p0" "free" (Mu (Scope (Bra
        [ br "p0" "drop" x_
        , br "p1" "pick" (sndL "p1" "notFree" y_)
        ]))))

waiter :: Proc String
waiter = Mu (Scope (Bra
  [ br "p0" "eat" (Var (BVar 0))
  , br "p1" "eat" (Var (BVar 0))
  , br "p2" "eat" (Var (BVar 0))
  ]))
