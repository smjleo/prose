{-# LANGUAGE ScopedTypeVariables #-}
module Main (main) where

import Data.Ratio ((%))
import Data.List (isInfixOf, isPrefixOf)
import Syntax.Process
import Syntax.Binder
import Syntax.RegularTree
import Syntax.WellFormed
import Normalize.Passes
import Typing.Types
import Typing.Infer
import Examples.DiningPhilosophers
import Examples.Tricky
import Typing.Pretty
import Typing.Subtype
import Output.Prose (proseType, proseProgram)
import Frontend.Parser (parseProc, parseProgram, parseDecls)
import Typing.Check     (runChecks, crName, crVerdict, Verdict(..))

-- Convenience
p_ :: Prob
p_ = case mkProb (1 % 3) of Right x -> x; Left e -> error e

pp, qq :: Role
pp = Role "p1"; qq = Role "p2"
l1, l2 :: Label
l1 = Label "l1"; l2 = Label "l2"

-- mu X. p1!l1<e1>.X   (X is bound index 0)
recSend :: Expr -> Proc String
recSend e = Mu (Scope (Sel pp l1 e (Var (BVar 0))))

check :: String -> Bool -> IO ()
check name ok = putStrLn ((if ok then "PASS  " else "FAIL  ") ++ name)

-- The 3-philosopher dining table in PROMT surface syntax. Each philosopher
-- flips on which fork to pick first; a fork is shared by two philosophers and
-- alternately grants/denies it. (Inner @mu@s that precede an outer @+@ are
-- parenthesized so the recursion is scoped correctly.)
diningProgram :: String
diningProgram = unlines
  [ phil "p0" "f0" "f1", phil "p1" "f1" "f2", phil "p2" "f2" "f0"
  , fork "f0" "p0" "p2", fork "f1" "p1" "p0", fork "f2" "p2" "p1"
  , "q = mu t . p0 ? eat . t + p1 ? eat . t + p2 ? eat . t" ]
  where
    -- second fork b (already holding a): if notFree drop a and restart X (=t);
    -- if free eat, drop a then b, restart X.
    second a b =
      b ++ " ! pick . ( " ++ b ++ " ? notFree . " ++ a ++ " ! drop . t + " ++ b
        ++ " ? free . q ! eat . " ++ a ++ " ! drop . " ++ b ++ " ! drop . t )"
    -- folded acquisition of fork a (retry loop Y = s): single pick site inside
    -- the loop; notFree loops, free proceeds to the second fork.
    acquire a b =
      "mu s . " ++ a ++ " ! pick . ( " ++ a ++ " ? notFree . s"
        ++ " + " ++ a ++ " ? free . " ++ second a b ++ " )"
    phil nm a b =
      nm ++ " = mu t . flip 0.5 ( " ++ acquire a b ++ " , " ++ acquire b a ++ " )"
    fork nm l r =
      nm ++ " = mu t . "
        ++ l ++ " ? pick . " ++ l ++ " ! free . ( mu s . ( " ++ l ++ " ? drop . t + "
        ++ r ++ " ? pick . " ++ r ++ " ! notFree . s ) )"
        ++ " + " ++ r ++ " ? pick . " ++ r ++ " ! free . ( mu s . ( " ++ r ++ " ? drop . t + "
        ++ l ++ " ? pick . " ++ l ++ " ! notFree . s ) )"

main :: IO ()
main = do
  -- regularTreeEq: identical recursive sends are equal
  check "recSend e == recSend e (exact)"
        (regularTreeEq (recSend (ENat 1)) (recSend (ENat 1)))

  -- payload-exact: differing payloads are NOT regular-tree-equal
  check "recSend 1 /= recSend 2 (payload-exact)"
        (not (regularTreeEq (recSend (ENat 1)) (recSend (ENat 2))))

  -- equirecursive: mu X.a.X  ~  a. mu X.a.X  (one unfold)
  check "mu X.a.X ~ unfold(mu X.a.X)"
        (regularTreeEq (recSend (ENat 1)) (unfold (recSend (ENat 1))))

  -- collapse: flip p P P -> P (no ghost)
  let dup = Flip p_ (recSend (ENat 1)) (recSend (ENat 1))
  check "collapse (flip p P P) == P"
        (collapse dup == recSend (ENat 1))

  -- collapse: if c P P -> Ghost [BoolCheck c] P
  let ifdup = If (EBool True) Nil Nil :: Proc String
  check "collapse (if c P P) keeps BoolCheck"
        (collapse ifdup == Ghost [BoolCheck (EBool True)] Nil)

  -- prefix extraction with differing payloads -> EFlipChoice retains both
  let shared = Flip p_ (Sel pp l1 (ENat 1) Nil) (Sel pp l1 (ENat 2) Nil) :: Proc String
      want   = Sel pp l1 (EFlipChoice p_ (ENat 1) (ENat 2)) (Flip p_ Nil Nil)
  check "extractPrefix combines differing payloads"
        (extractPrefix shared == want)

  -- disjoint sends under flip are left alone (already canonical)
  let disjoint = Flip p_ (Sel pp l1 (ENat 1) Nil) (Sel qq l2 (ENat 2) Nil) :: Proc String
  check "extractPrefix leaves disjoint sends untouched"
        (extractPrefix disjoint == disjoint)

  putStrLn "--- driver ---"

  -- Rotation emerges from the driver:
  --   mu X. p1!l1<0>. flip p (X) (p2!l2<9>.0)
  --     ==>  p1!l1<0>. mu g. flip p (p1!l1<0>.g) (p2!l2<9>.0)
  let e0  = ENat 0
      e9  = ENat 9
      src = Mu (Scope (Sel pp l1 e0
                        (Flip p_ (Var (BVar 0)) (Sel qq l2 e9 Nil)))) :: Proc String
      expect = Sel pp l1 e0
                 (Mu (Scope (Flip p_ (Sel pp l1 e0 (Var (BVar 0)))
                                     (Sel qq l2 e9 Nil))))
  check "rotation emerges: mu X.a.flip(X)(b) normalizes as expected"
        (normalize src == expect)

  -- Differing-payload loop routes to combine + tie:
  --   flip p (mu X.p1!l1<1>.X) (mu X.p1!l1<2>.X)
  --     ==>  mu g. p1!l1<1 (+)_p 2>. g
  let dpLoop = Flip p_ (recSend (ENat 1)) (recSend (ENat 2)) :: Proc String
      dpWant = Mu (Scope (Sel pp l1 (EFlipChoice p_ (ENat 1) (ENat 2)) (Var (BVar 0))))
  check "differing-payload loop -> mu g. send<combine>. g"
        (normalize dpLoop == dpWant)

  -- Soundness on the nested mutual-recursion case: result must be regular-tree
  -- equivalent to the input (type/tree preserving) even though, as discussed,
  -- the current tie-on-any-hit driver may leave a not-yet-canonical residual.
  let aR = Role "a"; bR = Role "b"; cR = Role "c"
      la = Label "la"; lb = Label "lb"; lc = Label "lc"
      nested = Mu (Scope (Flip p_
                  (Sel aR la e0 (Var (BVar 0)))
                  (Sel bR lb e0
                    (Flip p_ (Var (BVar 0)) (Sel cR lc e0 Nil))))) :: Proc String
  check "nested mutual recursion: normalize terminates & preserves tree"
        (regularTreeEq (normalize nested) nested)

  putStrLn "--- contractivity ---"

  -- mu X. flip p (X) (q!l2.0)  is NON-contractive (X bare under flip)
  let badFlip = Mu (Scope (Flip p_ (Var (BVar 0)) (Sel qq l2 e9 Nil))) :: Proc String
  check "reject mu X. flip p X Q"            (not (contractive badFlip))
  check "mu X. X is non-contractive"         (not (contractive (Mu (Scope (Var (BVar 0))) :: Proc String)))
  check "normalizeWF rejects non-contractive" (either (const True) (const False) (normalizeWF badFlip))

  -- the nested term has every X guarded by a prefix => contractive
  let aR = Role "a"; bR = Role "b"; cR = Role "c"
      la = Label "la"; lb = Label "lb"; lc = Label "lc"
      nested = Mu (Scope (Flip p_
                  (Sel aR la e0 (Var (BVar 0)))
                  (Sel bR lb e0
                    (Flip p_ (Var (BVar 0)) (Sel cR lc e0 Nil))))) :: Proc String
  check "accept the nested mutual-recursion term" (contractive nested)

  putStrLn "--- guard-aware canonical forms ---"

  -- nested now normalizes to a fully canonical form (no bare var under any flip)
  let nestedWant =
        Mu (Scope (Flip p_
          (Sel aR la e0 (Var (BVar 0)))
          (Sel bR lb e0
            (Mu (Scope (Flip p_
              (Flip p_ (Sel aR la e0 (Var (BVar 1))) (Sel bR lb e0 (Var (BVar 0))))
              (Sel cR lc e0 Nil)))))))
  check "nested -> canonical (guarded var under inner flip)"
        (normalize nested == nestedWant)

  -- mu-under-flip cleanup: flip p (mu Y. flip q (a.Y)(d.0)) (c.0)
  let dR = Role "d"; ld = Label "ld"
      muUnder = Flip p_
                  (Mu (Scope (Flip p_ (Sel aR la e0 (Var (BVar 0))) (Sel dR ld e0 Nil))))
                  (Sel cR lc e0 Nil) :: Proc String
      muUnderWant =
        Flip p_
          (Flip p_
             (Sel aR la e0 (Mu (Scope (Flip p_ (Sel aR la e0 (Var (BVar 0)))
                                                (Sel dR ld e0 Nil)))))
             (Sel dR ld e0 Nil))
          (Sel cR lc e0 Nil)
  check "mu-under-flip is unfolded under the guard"
        (normalize muUnder == muUnderWant)
  check "canonical forms preserve the tree (nested, muUnder)"
        (regularTreeEq (normalize nested) nested
         && regularTreeEq (normalize muUnder) muUnder)

  putStrLn "--- typing ---"

  check "infer 0 = end"
        (infer (Nil :: Proc String) == Right TEnd)
  check "infer p1!l1<5>.0 = (+)p1!1:l1<nat>.end"
        (infer (Sel pp l1 (ENat 5) Nil :: Proc String)
           == Right (TSel [[SBranch pp (1 % 1) l1 SNat TEnd]]))

  -- differing-payload loop: normalizes flip away into a recursive send
  let dpLoop = Flip p_ (recSend (ENat 1)) (recSend (ENat 2)) :: Proc String
      dpType = TMu (STScope (TSel [[SBranch pp (1 % 1) l1 SNat (TRecVar 0)]]))
  check "type of normalized differing-payload loop"
        (infer (normalize dpLoop) == Right dpType)

  -- rotation result: flip survives, typed by the disjoint M-SEL merge
  let src = Mu (Scope (Sel pp l1 e0
                        (Flip p_ (Var (BVar 0)) (Sel qq l2 e9 Nil)))) :: Proc String
      srcType =
        TSel [[ SBranch pp (1 % 1) l1 SNat
                  (TMu (STScope
                     (TSel [[ SBranch pp (1 % 3) l1 SNat (TRecVar 0)
                            , SBranch qq (2 % 3) l2 SNat TEnd ]]))) ]]
  check "type of normalized rotation term (flip merged by weight)"
        (infer (normalize src) == Right srcType)

  putStrLn "--- dining philosophers ---"

  -- all three are contractive and normalize successfully
  check "philosophers contractive"
        (all contractive [philosopher0, fork1, waiter])
  check "philosophers normalizeWF ok"
        (all (either (const False) (const True) . normalizeWF)
             [philosopher0, fork1, waiter])

  -- Q : mu t. &{ p_i?eat.t | i in 0..2 }
  check "Q types as recursive 3-way eat-branching"
        (case infer (normalize waiter) of
           Right (TMu (STScope (TBra bs))) ->
             map (\(Role r, Label l, s, t) -> (r, l, s, t)) bs
               == [ ("p0","eat",SUnit,TRecVar 0)
                  , ("p1","eat",SUnit,TRecVar 0)
                  , ("p2","eat",SUnit,TRecVar 0) ]
           _ -> False)

  -- F1 : mu t. &{ pick from p1 + pick from p0 }
  check "F1 types as recursive 2-way pick-branching"
        (case infer (normalize fork1) of
           Right (TMu (STScope (TBra bs))) ->
             [ (r, l) | (Role r, Label l, _, _) <- bs ] == [("p1","pick"),("p0","pick")]
           _ -> False)

  -- P0 : the flip becomes ONE distribution, two pick branches weighted 1/2,1/2,
  -- to forks f0 and f1 (the disjoint M-SEL merge). No bare var/mu under a flip.
  check "P0 flip merges to one 1/2-1/2 distribution over f0,f1"
        (case infer (normalize philosopher0) of
           Right (TMu (STScope (TSel [d]))) ->
             [ (r, l, w) | SBranch (Role r) w (Label l) _ _ <- d ]
               == [ ("f0", "pick", 1 % 2), ("f1", "pick", 1 % 2) ]
           _ -> False)

  putStrLn "--- value binder ---"

  -- p?req(x:nat). p!resp<x>.0   binds x:nat, then sends it back
  let echoP = Bra [ (Role "p", Label "req", SNat, "x",
                       Sel (Role "p") (Label "resp") (EVar "x") Nil) ] :: Proc String
      echoT = TBra [ (Role "p", Label "req", SNat,
                       TSel [[SBranch (Role "p") (1 % 1) (Label "resp") SNat TEnd]]) ]
  check "received value x:nat is in scope for the reply payload"
        (infer (normalize echoP) == Right echoT)
  -- using an unbound value variable is rejected
  check "unbound value variable is rejected"
        (either (const True) (const False)
                (infer (Sel (Role "p") (Label "l") (EVar "nope") Nil :: Proc String)))

  putStrLn "--- subtyping verification ---"

  -- subtyping is reflexive on every type we infer
  check "subtype reflexive on inferred philosopher type"
        (case infer (normalize philosopher0) of
           Right t -> subtype t t
           Left _  -> False)

  -- hand-derived philosopher type (i=0, p=1/2), encoded independently
  let sel1 r w l k = TSel [[ SBranch (Role r) w (Label l) SUnit k ]]
      bbT r l k    = (Role r, Label l, SUnit, k)
      proceed ti fa fb =
        sel1 fb (1 % 1) "pick" (TBra
          [ bbT fb "notFree" (sel1 fa (1 % 1) "drop" (TRecVar ti))
          , bbT fb "free"    (sel1 "q" (1 % 1) "eat"
                               (sel1 fa (1 % 1) "drop"
                                 (sel1 fb (1 % 1) "drop" (TRecVar ti)))) ])
      loopF fa fb = TMu (STScope (sel1 fa (1 % 1) "pick" (TBra
                      [ bbT fa "notFree" (TRecVar 0)
                      , bbT fa "free"    (proceed 1 fa fb) ])))
      contF fa fb = TBra [ bbT fa "notFree" (loopF fa fb)
                         , bbT fa "free"    (proceed 0 fa fb) ]
      handType = TMu (STScope (TSel [[
                   SBranch (Role "f0") (1 % 2) (Label "pick") SUnit (contF "f0" "f1")
                 , SBranch (Role "f1") (1 % 2) (Label "pick") SUnit (contF "f1" "f0") ]]))
  check "inferred philosopher type <= hand-derived type"
        (either (const False) (\t -> subtype t handType) (infer (normalize philosopher0)))
  check "inferred philosopher type EQUALS hand-derived type"
        (either (const False) (\t -> typeEq t handType) (infer (normalize philosopher0)))

  putStrLn "--- normalization-critical example ---"

  check "tricky example is contractive"      (contractive tricky)
  check "tricky example normalizes"          (either (const False) (const True) (normalizeWF tricky))
  check "tricky example types after normalization"
        (either (const False) (const True) (infer (normalize tricky)))

  -- The inner M-SUM merge reweights the if-action by 1/4 and each fork action
  -- by 3/8 (= 3/4 * 1/2). The 3/8 weight can ONLY arise from that product, so
  -- its presence (with 1/4) is a faithful signature that M-SUM fired.
  let allWeights t = case t of
        TEnd            -> []
        TRecVar _       -> []
        TMu (STScope b) -> allWeights b
        TBra bs         -> concatMap (\(_,_,_,c) -> allWeights c) bs
        TSel ds         -> concatMap (concatMap (\b -> sbWeight b : allWeights (sbCont b))) ds
  check "tricky: M-SUM reweighting present (weights 1/4 and 3/8 appear)"
        (case infer (normalize tricky) of
           Right t -> (1 % 4) `elem` allWeights t && (3 % 8) `elem` allWeights t
           Left _  -> False)

  putStrLn ""
  putStrLn "Inferred type of the tricky example:"
  case infer (normalize tricky) of
    Right t -> putStrLn ("  " ++ pretty t)
    Left e  -> putStrLn ("  ERROR: " ++ e)

  putStrLn "--- nondeterministic-sum subtyping (sanity) ---"

  -- mu X. p!l1.p!l2.X : deterministic alternation
  let tDet = TMu (STScope (TSel [[ SBranch (Role "p") (1%1) (Label "l1") SUnit
                                     (TSel [[ SBranch (Role "p") (1%1) (Label "l2") SUnit (TRecVar 0) ]]) ]]))
  -- the nondeterministic-sum type collecting the two program points
      tB   = TMu (STScope (TSel [ [ SBranch (Role "p") (1%1) (Label "l1") SUnit (TRecVar 0) ]
                                 , [ SBranch (Role "p") (1%1) (Label "l2") SUnit (TRecVar 0) ] ]))
  check "p!l1.p!l2 loop is typable by the nondet-sum type (tDet <= tB)"
        (subtype tDet tB)
  check "the nondet-sum type is strictly larger (not tB <= tDet)"
        (not (subtype tB tDet))
  check "they are not bisimilar"
        (not (typeEq tDet tB))

  putStrLn "--- overlapping [M-SEL]: flip of two ifs over shared labels ---"

  -- flip 1/2 (if C1 (p!l1.q!a) (p!l2.q!c)) (if C2 (p!l1.q!b) (p!l2.q!d))
  let sel r l k = Sel (Role r) (Label l) EUnit k
      exFlip =
        Flip (either error id (mkProb (1 % 2)))
          (If (EBool True) (sel "p" "l1" (sel "q" "a" Nil)) (sel "p" "l2" (sel "q" "c" Nil)))
          (If (EBool True) (sel "p" "l1" (sel "q" "b" Nil)) (sel "p" "l2" (sel "q" "d" Nil)))
  case infer (normalize exFlip) of
    Left e  -> check ("overlapping M-SEL example infers (" ++ e ++ ")") False
    Right t -> do
      let s = pretty t
          has sub = sub `isInfixOf` s
      check "overlap M-SEL: diagonal l1 merges continuations q!a,q!b at 1/2 each"
            (has "p!1/1:l1.(+){q!1/2:a.end, q!1/2:b.end}")
      check "overlap M-SEL: diagonal l2 merges continuations q!c,q!d at 1/2 each"
            (has "p!1/1:l2.(+){q!1/2:c.end, q!1/2:d.end}")
      check "overlap M-SEL: off-diagonal l1/l2 cross-term present (a with d)"
            (has "p!1/2:l1.(+){q!1/1:a.end}, p!1/2:l2.(+){q!1/1:d.end}")
      check "overlap M-SEL: four nondeterministic alternatives"
            (countSub "(+) (+)" s + 1 == 4)

  putStrLn "--- normalization removes overlapping merges (flip-over-if distribution) ---"
  let nsel r l k = Sel (Role r) (Label l) EUnit k
      nflp a b   = Flip (either error id (mkProb (1 % 2))) a b
      nflpW p a b = Flip (either error id (mkProb p)) a b
      nqa = nsel "q" "a" Nil; nqb = nsel "q" "b" Nil
      nqc = nsel "q" "c" Nil; nqd = nsel "q" "d" Nil
      typed    = either (const False) (const True)
      rejected = either (const True)  (const False)
      strictEqFull e = case (inferStrict (normalize e), infer (normalize e)) of
                         (Right a, Right b) -> typeEq a b
                         _                  -> False
      exA = nflp (If (EBool True) (nsel "p" "l1" nqa) (nsel "p" "l2" nqc))
                 (If (EBool True) (nsel "p" "l1" nqb) (nsel "p" "l2" nqd))
      exC = nflp (nsel "p" "l1" nqa) (nsel "p" "l1" nqb)
      -- nested flips, shared labels, purely probabilistic (no if)
      exD = nflp (nflp (nsel "p" "l1" nqa) (nsel "p" "l2" nqc))
                 (nflp (nsel "p" "l1" nqb) (nsel "p" "l2" nqd))
      -- weighted variant: outer 1/2, inner 1/4 and 3/4
      exW = nflpW (1 % 2)
                  (nflpW (1 % 4) (nsel "p" "l1" nqa) (nsel "p" "l2" nqc))
                  (nflpW (3 % 4) (nsel "p" "l1" nqb) (nsel "p" "l2" nqd))
  check "flip-of-ifs needs an overlapping M-SEL when NOT normalized"
        (rejected (inferStrict exA))
  check "flip-of-ifs: normalization makes it disjoint-only typable"
        (typed (inferStrict (normalize exA)))
  check "flip-of-ifs: strict-normalized type equals full inferred type"
        (strictEqFull exA)
  check "bare overlapping flip(l1)(l1) is disjoint-only after normalization"
        (typed (inferStrict (normalize exC)))
  check "nested-flip overlap needs overlapping M-SEL when NOT normalized"
        (rejected (inferStrict exD))
  check "nested-flip overlap: label-factoring makes it disjoint-only typable"
        (typed (inferStrict (normalize exD)))
  check "nested-flip: strict-normalized type equals full inferred type"
        (strictEqFull exD)
  check "label-factoring readjusts weights: l1 carries q!1/4:a,q!3/4:b"
        (case infer (normalize exW) of
           Right t -> "p!1/2:l1.(+){q!1/4:a.end, q!3/4:b.end}" `isInfixOf` pretty t
           _       -> False)
  check "label-factoring readjusts weights: l2 carries q!3/4:c,q!1/4:d"
        (case infer (normalize exW) of
           Right t -> "p!1/2:l2.(+){q!3/4:c.end, q!1/4:d.end}" `isInfixOf` pretty t
           _       -> False)
  check "weighted nested-flip: strict-normalized type equals full inferred type"
        (strictEqFull exW)

  putStrLn "--- flip over incompatible shapes / Prose export ---"
  check "flip over an end-typed and a sel-typed branch fails to type"
        (rejected (infer (normalize (nflp Nil (nsel "p" "l1" Nil)))))
  check "flip over a sel-typed and an end-typed branch fails to type (other order)"
        (rejected (infer (normalize (nflp (nsel "p" "l1" Nil) Nil))))
  check "Prose: single distribution renders as (+) with decimal weight and <Sort> send"
        (case proseType (TSel [[SBranch (Role "p") (1 % 1) (Label "l") SInt TEnd]]) of
           Right s -> "(+) {" `isInfixOf` s && "p ! 1.0 : l<Int> . end" `isInfixOf` s
           _       -> False)
  check "Prose: branching renders as & with (Sort) receive payload"
        (case proseType (TBra [(Role "q", Label "datum", SInt, TEnd)]) of
           Right s -> "& {" `isInfixOf` s && "q ? datum(Int) . end" `isInfixOf` s
           _       -> False)
  check "Prose: bare SUnit label has no payload annotation"
        (case proseType (TBra [(Role "q", Label "stop", SUnit, TEnd)]) of
           Right s -> "q ? stop . end" `isInfixOf` s
           _       -> False)
  check "Prose: recursion prints named binder mu t. ... t"
        (case proseType (TMu (STScope (TBra [(Role "p", Label "go", SUnit, TRecVar 0)]))) of
           Right s -> "mu t. & {" `isInfixOf` s && "p ? go . t" `isInfixOf` s
           _       -> False)
  let loopL2 = TMu (STScope (TSel [[ SBranch (Role "q") (1 % 1) (Label "l2") SUnit (TRecVar 0) ]]))
      ndType = TSel
        [ [ SBranch (Role "q") (3 % 5) (Label "l1") SUnit TEnd
          , SBranch (Role "q") (2 % 5) (Label "l2") SUnit loopL2 ]
        , [ SBranch (Role "q") (2 % 5) (Label "l1") SUnit TEnd
          , SBranch (Role "q") (3 % 5) (Label "l2") SUnit loopL2 ] ]
  check "Prose: nondeterministic sum renders as (+) {...} + (+) {...}"
        (case proseType ndType of
           Right s -> "+ (+) {" `isInfixOf` s
                      && "q ! 0.6 : l1 . end" `isInfixOf` s
                      && "q ! 0.4 : l1 . end" `isInfixOf` s
           _       -> False)

  putStrLn "--- surface-syntax front-end ---"
  let workerSrc = unlines
        [ "starter = workerA1 ! datum<0> . end"
        , "workerA1 = starter ? datum(x:Int) . mu t ."
        , "  flip 0.5 ( workerB1 ! datum<x> . workerC1 ? result(y:Int) . t , workerB1 ! stop . end )"
        , "workerB1 = mu t . workerA1 ? datum(x:Int) . workerC1 ! datum<x> . t"
        , "         + workerA1 ? stop . workerC1 ! stop . end"
        , "workerC1 = mu t . workerB1 ? datum(x:Int) . workerA1 ! result<x> . t"
        , "         + workerB1 ? stop . end" ]
      flipIfsSrc = "flip 0.5 ( if true then p!l1.q!a.end else p!l2.q!c.end ,"
                ++ " if true then p!l1.q!b.end else p!l2.q!d.end )"
      typedP   = either (const False) (const True)
  check "parse: send to nil ('0' and 'end' both mean nil)"
        (parseProc "p ! l . 0" == Right (Sel (Role "p") (Label "l") EUnit Nil)
         && parseProc "p ! l . end" == Right (Sel (Role "p") (Label "l") EUnit Nil))
  check "parse: branching with '+', payload sorts, and bound value var types"
        (case parseProc "p ? a (x:Int) . p ! b <x> . end + p ? c . end" of
           Right pr -> typedP (infer (normalize pr))
           Left _   -> False)
  check "parse: recursion mu/var round-trips to a recursive type"
        (case parseProc "mu t . p ! l . t" of
           Right pr -> case infer (normalize pr) of Right (TMu _) -> True; _ -> False
           Left _   -> False)
  check "parse: flip of two sends infers a 1/2-1/2 distribution"
        (case parseProc "flip 0.5 ( p ! a . end , p ! b . end )" of
           Right pr -> case infer (normalize pr) of
                         Right (TSel [d]) -> map sbWeight d == [1 % 2, 1 % 2]
                         _                -> False
           Left _   -> False)
  check "parse: a four-binding program parses"
        (case parseProgram workerSrc of Right bs -> length bs == 4; Left _ -> False)
  check "parse: worker program participants all type-check"
        (case parseProgram workerSrc of
           Right bs -> all (typedP . infer . normalize . snd) bs
           Left _   -> False)
  check "parse: flip-of-ifs parses and is strict-typable after normalization"
        (case parseProc flipIfsSrc of
           Right pr -> typedP (inferStrict (normalize pr))
           Left _   -> False)
  -- a Ghost-wrapped selection under a flip must be flattened (Ghost is type-
  -- transparent), NOT fall back to an overlapping merge. asDist sees through it.
  let half2 = either error id (mkProb (1 % 2))
      ghostFlip = Flip half2
        (Ghost [BoolCheck (EBool True)]
               (Sel (Role "p") (Label "a") EUnit (Sel (Role "s") (Label "u") EUnit Nil)))
        (Sel (Role "p") (Label "a") EUnit (Sel (Role "s") (Label "v") EUnit Nil))
  check "Ghost-wrapped selection under a flip is factored, not overlap-merged"
        (typedP (inferStrict (normalize ghostFlip)))

  putStrLn "--- overlap is rejected (not merged); ill-formed shapes; brace grouping ---"
  let ovl = Flip half2 (Sel (Role "p") (Label "a") EUnit (Sel (Role "q") (Label "b") EUnit Nil))
                       (Sel (Role "p") (Label "a") EUnit (Sel (Role "q") (Label "c") EUnit Nil))
      disjointBra = Flip half2 (Bra [(Role "q", Label "m", SUnit, "_", Nil)])
                               (Bra [(Role "q", Label "n", SUnit, "_", Nil)])
      mixedChoice = Flip half2 (Sel (Role "p") (Label "a") EUnit Nil)
                               (Bra [(Role "q", Label "m", SUnit, "_", Nil)])
  check "overlap is rejected by default inference (not silently merged)"
        (rejected (infer ovl))
  check "the same flip is typable after normalization (overlap removed)"
        (typedP (infer (normalize ovl)))
  check "flip over branchings with disjoint labels is rejected (empty merged branching)"
        (rejected (infer (normalize disjointBra)))
  check "flip mixing a send (!) and a receive (?) is rejected (mixed choice)"
        (rejected (infer (normalize mixedChoice)))
  check "parse: brace grouping in flip branches"
        (case parseProc "flip 0.5 ( { p!a.end } , { p!b.end } )" of
           Right pr -> typedP (infer (normalize pr)); _ -> False)
  check "parse: brace grouping in if branches"
        (case parseProc "if true then { p!a.end } else { p!b.end }" of
           Right pr -> typedP (infer (normalize pr)); _ -> False)

  putStrLn "--- if-join (joinIf) and its relation to subtyping ---"
  let rp = Role "p"; rq = Role "q"
      la = Label "a"; lb = Label "b"; ll = Label "l"
      selA = Sel rp la EUnit Nil
      selB = Sel rp lb EUnit Nil
      ifSel  = If (EBool True) selA selB                                   -- if C (p!a)(p!b)
      ifSame = If (EBool True) selA selA                                   -- if C (p!a)(p!a)
      ifBra  = If (EBool True) (Bra [(rq, la, SUnit, "_", Nil)])           -- if C (q?a)(q?b)
                               (Bra [(rq, lb, SUnit, "_", Nil)])
      ifPre  = If (EBool True) (Sel rp ll EUnit (Sel rq la EUnit Nil))     -- if C (p!l.q!a)(p!l.q!b)
                               (Sel rp ll EUnit (Sel rq lb EUnit Nil))
      inferN = infer . normalize
  check "joinIf: if over two selections is the nondeterministic union (a 2-distribution Sigma)"
        (case inferN ifSel of Right (TSel ds) -> length ds == 2; _ -> False)
  check "joinIf: that union is a common SUPERtype of both branches (consistent with subtyping)"
        (case (inferN ifSel, inferN selA, inferN selB) of
           (Right j, Right ta, Right tb) -> subtype ta j && subtype tb j
           _ -> False)
  check "joinIf: equal branches collapse (Ghost) to the branch type, introducing no Sigma"
        (case (inferN ifSame, inferN selA) of
           (Right t, Right b) -> typeEq t b && (case t of TSel ds -> length ds == 1; _ -> False)
           _                  -> False)
  check "joinIf: if over branchings with no shared label is rejected (empty intersection)"
        (rejected (inferN ifBra))
  check "joinIf: an if over a shared send stays distributed (minimal Sigma), not hoisted"
        (case inferN ifPre of
           Right (TSel [[b1], [b2]]) -> sbLabel b1 == ll && sbLabel b2 == ll
           _                         -> False)
  -- the distributed (minimal) inferred type is <= a spec in EITHER shape:
  -- the factored former AND the distributed latter. This is the gap closure.
  check "if over shared send: inferred type matches a spec in factored OR distributed shape"
        (case inferN ifPre of
           Right j ->
             let former = TSel [ [ SBranch rp 1 ll SUnit
                                     (TSel [ [SBranch rq 1 la SUnit TEnd]
                                           , [SBranch rq 1 lb SUnit TEnd] ]) ] ]
                 latter = TSel [ [SBranch rp 1 ll SUnit (TSel [[SBranch rq 1 la SUnit TEnd]])]
                               , [SBranch rp 1 ll SUnit (TSel [[SBranch rq 1 lb SUnit TEnd]])] ]
             in subtype j former && subtype j latter
           _ -> False)
  -- branching (&) under an if: the LUB is the branching on the INTERSECTION of
  -- labels, with continuations joined; disjoint labels are trimmed (obligations).
  let braBoth = Bra [ (rq, la, SUnit, "_", Sel rp (Label "x") EUnit Nil)
                    , (rq, lb, SUnit, "_", Sel rp (Label "y") EUnit Nil) ]   -- q?a + q?b
      braOne  = Bra [ (rq, la, SUnit, "_", Sel rp (Label "z") EUnit Nil) ]   -- q?a
      ifBraInt = If (EBool True) braBoth braOne
      ifBraDis = If (EBool True) (Bra [(rq, la, SUnit, "_", Nil)])
                                 (Bra [(rq, lb, SUnit, "_", Nil)])
  check "if over branchings keeps the shared label: (q?a+q?b) `if` (q?a) types as q?a"
        (case inferN ifBraInt of
           Right (TBra [(r, l, _, _)]) -> r == rq && l == la
           _                          -> False)
  check "if over branchings with empty intersection (q?a vs q?b) is rejected"
        (rejected (inferN ifBraDis))
  -- the same &-LUB computed directly on types by joinIf, and it is the least
  -- common supertype: &{a,b} `join` &{a} = &{a}, with both branches <= it.
  let tBoth = TBra [(rq, la, SUnit, TEnd), (rq, lb, SUnit, TEnd)]
      tOne  = TBra [(rq, la, SUnit, TEnd)]
  check "joinIf on &-types is the intersection LUB and a common supertype of both"
        (case joinIf tBoth tOne of
           Right j -> j == tOne && subtype tBoth j && subtype tOne j
           Left _  -> False)
  -- M-BRA merge alpha-renames: two branches sharing a label but binding the
  -- received value to different names (x vs y) merge to one fresh binder.
  check "M-BRA alpha-renames branches that bind a shared label to different vars"
        (typedP (inferN (If (EBool True)
                            (Bra [(rq, la, SNat, "x", Sel rp (Label "fwd") (EVar "x") Nil)])
                            (Bra [(rq, la, SNat, "y", Sel rp (Label "fwd") (EVar "y") Nil)]))))
  -- recursion under an if: normBranch head-unfolds (whnfMu) the leading mu, so
  -- joinIf is never handed two recursive branchings; the recursion is recovered
  -- AROUND the join. (q?a.Z + q?b.Z)* `if` (q?a.X)* thus gives mu t.&{q?a.t}.
  let muBraAB = Mu (Scope (Bra [ (rq, la, SUnit, "_", Var (BVar 0))
                               , (rq, lb, SUnit, "_", Var (BVar 0)) ]))
      muBraA  = Mu (Scope (Bra [ (rq, la, SUnit, "_", Var (BVar 0)) ]))
      muSelA  = Mu (Scope (Sel rp la EUnit (Var (BVar 0))))
      muSelB  = Mu (Scope (Sel rp lb EUnit (Var (BVar 0))))
  check "if over recursive branchings: mu head-unfolded, intersection LUB is recursive"
        (fmap pretty (inferN (If (EBool True) muBraAB muBraA)) == Right "mu t0. &{q?a.t0}")
  check "if over recursive selections (diff label): nondeterministic union of two recursions"
        (case inferN (If (EBool True) muSelA muSelB) of
           Right (TSel ds) -> length ds == 2
           _               -> False)

  putStrLn "--- checking a process against a user-specified type (Prose type syntax) ---"
  let chkProg = unlines
        [ "a = mu t . b ! ping . t"
        , "a : mu t . (+) { b ! 1.0 : ping . t }"                     -- exact
        , "c = s ! x . end"
        , "c : (+) { s ! 1.0 : x . end } + (+) { s ! 1.0 : y . end }" -- selection subtype
        , "d = r ? x . end + r ? y . end"
        , "d : & { r ? x . end }"                                     -- branching subtype
        , "e = if true then s ! l . t1 ! x . end else s ! l . t1 ! y . end"
        , "e : (+) { s ! 1.0 : l . (+) { t1 ! 1.0 : x . end }"        -- factored form
        ++                       " + (+) { t1 ! 1.0 : y . end } }"
        , "f = s ! z . end"
        , "f : (+) { s ! 1.0 : x . end } + (+) { s ! 1.0 : y . end }" -- violation
        ]
      verdictOf nm = case parseDecls chkProg of
                       Right ds -> lookup nm [ (crName r, crVerdict r) | r <- runChecks ds ]
                       Left _   -> Nothing
  check "spec check: exact match holds (Prose type)"
        (verdictOf "a" == Just Holds)
  check "spec check: selection subtype holds (impl offers fewer distribution points)"
        (verdictOf "c" == Just Holds)
  check "spec check: branching subtype holds (impl offers more inputs)"
        (verdictOf "d" == Just Holds)
  check "spec check: factored selection in Prose matches the (factored) inferred type"
        (verdictOf "e" == Just Holds)
  check "spec check: a genuine violation is reported (not a subtype)"
        (case verdictOf "f" of Just (Violates _ _) -> True; _ -> False)

  putStrLn "--- 3 dining philosophers: PROMT -> AST -> type -> Prose (full pipeline) ---"

  case parseProgram diningProgram of
    Left e   -> check ("3-philosophers: parses (" ++ e ++ ")") False
    Right bs -> do
      check "3-philosophers: program parses to 7 role bindings"
            (length bs == 7)
      case proseProgram bs of
        Left e   -> check ("3-philosophers: full pipeline to Prose (" ++ e ++ ")") False
        Right out -> do
          check "3-philosophers: full pipeline (parse->normalize->infer->Prose) succeeds"
                (length out > 0)
          -- q: observer is exactly the three-eat external choice
          check "dining q matches the Prose example exactly"
                (("q : mu t. & {\n  p0 ? eat . t,\n  p1 ? eat . t,\n  p2 ? eat . t\n}")
                 `isInfixOf` out)
          -- p0: the flip on which fork to take first, and the eat in between
          check "dining p0 is a flip between picking f0 / f1 first, with q!eat"
                ("f0 ! 0.5 : pick" `isInfixOf` out
                 && "f1 ! 0.5 : pick" `isInfixOf` out
                 && "q ! 1.0 : eat" `isInfixOf` out)
          -- f0: two top-level pick branches (p0 and p2), grant 'free', deny 'notFree'
          check "dining f0 offers both p0?pick and p2?pick, granting free / denying notFree"
                ("p0 ? pick . (+) {\n    p0 ! 1.0 : free" `isInfixOf` out
                 && "p2 ? pick . (+) {\n    p2 ! 1.0 : free" `isInfixOf` out
                 && "notFree . s" `isInfixOf` out)
          -- the fork's hold-loop: after granting, await drop (release) or the
          -- other philosopher's pick (denied)
          check "dining f0 hold-loop awaits drop (release) or other's pick (denied)"
                ("p0 ? drop . t" `isInfixOf` out && "p2 ? pick" `isInfixOf` out)
  where
    countSub pat = go
      where go [] = 0
            go xs@(_:rest) | pat `isPrefixOf` xs = 1 + go (drop (length pat) xs)
                           | otherwise           = go rest