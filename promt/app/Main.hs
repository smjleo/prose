module Main (main) where

import Control.Exception (IOException, bracketOnError, catch, evaluate)
import Control.Monad (unless)
import Data.List (group, intercalate, isPrefixOf, sort, (\\))
import System.Directory (canonicalizePath, removeFile, renameFile)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.FilePath (takeDirectory)
import System.IO (hClose, hPutStr, hPutStrLn, openTempFile, stderr)
import Frontend.Parser (parseContext, parseDecls, Decl(..))
import Typing.Inference (infer)
import Typing.Types (SType)
import Output.Context (renderType)
import Typing.Check (CheckResult, checkContext, checkSpecs, allHold, reportLine)

data Command = Infer FilePath (Maybe FilePath)
             | Typecheck FilePath FilePath
             | Subtype FilePath FilePath

main :: IO ()
main = runMain `catch` ioErrorMessage
  where
    ioErrorMessage :: IOException -> IO ()
    ioErrorMessage err = failWith ("I/O error: " ++ show err)

runMain :: IO ()
runMain = do
  args <- getArgs
  case options args of
    Left err -> failWith (err ++ "\n" ++ usage)
    Right Nothing -> putStrLn usage
    Right (Just command) -> run command

usage :: String
usage = unlines
  [ "usage: promt infer <source.promt> [-o <output.ctx>]"
  , "       promt typecheck <source.promt> <spec.ctx>"
  , "       promt subtype <left.ctx> <right.ctx>"
  , "       promt <source.promt> [-o <output.ctx>]"
  , "       promt --help"
  , ""
  , "infer writes a ProSe-style type context; -o/--output saves it to a file."
  , "typecheck requires exactly the source participants in the specification."
  , "subtype checks each left participant against its matching right type."
  , "Use -- before filenames beginning with '-'."
  ]

options :: [String] -> Either String (Maybe Command)
options args
  | args `elem` [["--help"], ["-h"], ["infer", "--help"],
                 ["typecheck", "--help"], ["subtype", "--help"]] = Right Nothing
options ("typecheck" : args) = binary Typecheck args
options ("subtype" : args) = binary Subtype args
options ("infer" : args) = unary args
options args = unary args

unary :: [String] -> Either String (Maybe Command)
unary args = do
  (files, output) <- arguments True args
  case files of
    [file] -> Right (Just (Infer file output))
    [] -> Left "missing input file"
    _ -> Left "inference expects exactly one input file"

binary :: (FilePath -> FilePath -> Command) -> [String] -> Either String (Maybe Command)
binary command args = do
  (files, _) <- arguments False args
  case files of
    [left, right] -> Right (Just (command left right))
    _ -> Left "checking expects exactly two input files"

arguments :: Bool -> [String] -> Either String ([FilePath], Maybe FilePath)
arguments allowOutput = go [] Nothing
  where
    go files output [] = Right (reverse files, output)
    go files output ("--" : rest) = Right (reverse files ++ rest, output)
    go files output (flag : rest)
      | flag `elem` ["-o", "--output"] && allowOutput = case (output, rest) of
          (Just _, _) -> Left "output may only be specified once"
          (Nothing, file : more) -> go files (Just file) more
          _ -> Left (flag ++ " requires an output filename")
      | flag == "--prose" = Left "--prose is no longer needed: inferred types use .ctx syntax by default"
      | "-" `isPrefixOf` flag = Left ("unknown option: " ++ flag)
      | otherwise = go (flag : files) output rest

run :: Command -> IO ()
run (Infer file output) = do
  case output of
    Nothing -> pure ()
    Just target -> do
      sourcePath <- canonicalizePath file
      outputPath <- canonicalizePath target
      unless (sourcePath /= outputPath) (failWith "output must not overwrite the source file")
  (types, specs) <- sourceTypes file
  checkResults stderrReport specs
  bodies <- require (mapM (\(name,t) -> ((name ++ " : ") ++) <$> renderType t) types)
  writeOutput output (intercalate "\n\n" bodies ++ "\n")
run (Typecheck file specification) = do
  expected <- readContext specification
  (types, specs) <- sourceTypes file
  let missing = map fst types \\ map fst expected
      extra = map fst expected \\ map fst types
  unless (null missing && null extra) $ failWith (intercalate "\n"
    [label ++ intercalate ", " names | (label,names) <-
      [("missing type specifications: ",missing), ("unexpected type specifications: ",extra)],
      not (null names)])
  checkResults stderrReport specs
  checkResults putStrLn (checkContext types expected)
run (Subtype left right) = do
  leftTypes <- readContext left
  rightTypes <- readContext right
  checkResults putStrLn (checkContext leftTypes rightTypes)

sourceTypes :: FilePath -> IO ([(String, SType)], [CheckResult])
sourceTypes file = do
  ds <- readParsed parseDecls file
  let defs = [(name,p) | Def name p <- ds]
      duplicates = [name | name : _ : _ <- group (sort (map fst defs))]
  unless (not (null defs)) (failWith "source contains no process definitions")
  unless (null duplicates) (failWith ("duplicate process definition: " ++ intercalate ", " duplicates))
  types <- require $ mapM (\(name,p) -> case infer p of
    Left err -> Left ("process " ++ name ++ ": " ++ err)
    Right t -> Right (name,t)) defs
  pure (types, checkSpecs [(name,Right t) | (name,t) <- types] ds)

readContext :: FilePath -> IO [(String, SType)]
readContext = readParsed parseContext

readParsed :: (String -> Either String a) -> FilePath -> IO a
readParsed parse file = do
  src <- readFile file
  _ <- evaluate (length src)
  require $ case parse src of
    Left err -> Left (file ++ ": " ++ err)
    Right value -> Right value

checkResults :: (String -> IO ()) -> [CheckResult] -> IO ()
checkResults report results
  | allHold results = mapM_ (report . reportLine) results
  | otherwise = mapM_ (stderrReport . reportLine) results >> exitFailure

writeOutput :: Maybe FilePath -> String -> IO ()
writeOutput Nothing output = putStr output
writeOutput (Just file) output =
  bracketOnError (openTempFile (takeDirectory file) ".promt-context-")
    (\(temporary,handle) -> do
      hClose handle `catch` ignoreIO
      removeFile temporary `catch` ignoreIO)
    (\(temporary,handle) -> do
      hPutStr handle output
      hClose handle
      renameFile temporary file)
  where
    ignoreIO :: IOException -> IO ()
    ignoreIO _ = pure ()

require :: Either String a -> IO a
require = either failWith pure

stderrReport :: String -> IO ()
stderrReport = hPutStrLn stderr

failWith :: String -> IO a
failWith problem = stderrReport problem >> exitFailure
