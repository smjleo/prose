{-# LANGUAGE LambdaCase #-}

-- | Driver for the PROMT pipeline.
--
-- > promt [--prose] [FILE]

module Main (main) where

import System.Environment (getArgs)
import System.Exit        (exitFailure)
import System.IO          (hPutStrLn, stderr)
import Data.List          (isPrefixOf)
import Data.Ratio         ((%))
import Syntax.Process
import Normalize.Passes   (normalizeE)
import Typing.Infer       (infer)
import Typing.Pretty      (pretty)
import Output.Prose       (proseProgram)
import Frontend.Parser    (parseDecls, Decl(..))
import Typing.Check       (runChecks, allHold, reportLine)

main :: IO ()
main = do
  args <- getArgs
  let prose = "--prose" `elem` args
      files = [ a | a <- args, not ("-" `isPrefixOf` a) ]
  case files of
    (f : _) -> do
      src <- readFile f
      case parseDecls src of
        Left err -> hPutStrLn stderr ("parse error: " ++ err) >> exitFailure
        Right ds -> do
          emit prose [ (n, p) | Def n p <- ds ]
          let results = runChecks ds
          if null results
            then pure ()
            else do
              putStrLn ""
              putStrLn "checking processes against specified types:"
              mapM_ (putStrLn . reportLine) results
              if allHold results then pure () else exitFailure
    [] -> emit prose demo

emit :: Bool -> [(String, Proc String)] -> IO ()
emit True ps =
  case proseProgram ps of
    Left e  -> hPutStrLn stderr ("prose export failed: " ++ e) >> exitFailure
    Right s -> putStrLn s
emit False ps =
  mapM_ (\(n, p) -> putStrLn (n ++ " : " ++ either ("<error: " ++) pretty
                                     (normalizeE p >>= infer))) ps

-- A bundled demo (used when no file is given): a worker pipeline with Int
-- payloads, recursion, a flip, and branchings.
demo :: [(String, Proc String)]
demo =
  [ ("starter",  Sel (Role "workerA1") (Label "datum") (EInt 0) Nil)
  , ("workerA1", Bra [ (Role "starter", Label "datum", SInt, "x",
                          Mu (Scope (Flip half
                            (Sel (Role "workerB1") (Label "datum") (EVar "x")
                               (Bra [ (Role "workerC1", Label "result", SInt, "y", Var (BVar 0)) ]))
                            (Sel (Role "workerB1") (Label "stop") EUnit Nil)))) ])
  , ("workerB1", Mu (Scope (Bra
                   [ (Role "workerA1", Label "datum", SInt, "x",
                        Sel (Role "workerC1") (Label "datum") (EVar "x") (Var (BVar 0)))
                   , (Role "workerA1", Label "stop", SUnit, "_",
                        Sel (Role "workerC1") (Label "stop") EUnit Nil) ])))
  , ("workerC1", Mu (Scope (Bra
                   [ (Role "workerB1", Label "datum", SInt, "x",
                        Sel (Role "workerA1") (Label "result") (EVar "x") (Var (BVar 0)))
                   , (Role "workerB1", Label "stop", SUnit, "_", Nil) ])))
  ]
  where half = either error id (mkProb (1 % 2))