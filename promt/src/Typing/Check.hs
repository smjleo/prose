module Typing.Check
  ( CheckResult(..)
  , Verdict(..)
  , checkSpecs
  , checkContext
  , allHold
  , reportLine
  ) where

import Typing.Relations  (subtype, validateType)
import Typing.Types      (SType)
import Output.Context    (pretty)
import Frontend.Parser   (Decl(..))
import qualified Data.Map.Lazy as Map

data Verdict
  = Holds
  | Violates SType SType
  | NoProcess
  | NoSpecification
  | IllTyped String
  deriving (Eq, Show)

data CheckResult = CheckResult
  { crName    :: String
  , crVerdict :: Verdict
  } deriving (Eq, Show)

checkSpecs :: [(String, Either String SType)] -> [Decl] -> [CheckResult]
checkSpecs defs ds =
  [ CheckResult name (check name spec) | Spec name spec <- ds ]
  where
    -- Keep the first definition; unused inference results remain lazy.
    definitions = Map.fromListWith (\_ first -> first) defs
    check name spec = case validateType spec of
      Left e -> IllTyped ("specification " ++ name ++ ": " ++ e)
      Right () -> checkProcess name spec
    checkProcess name spec =
      case Map.lookup name definitions of
        Nothing   -> NoProcess
        Just result ->
          case result of
            Left e   -> IllTyped ("process " ++ name ++ ": " ++ e)
            Right inferred
              | subtype inferred spec -> Holds
              | otherwise -> Violates inferred spec

checkContext :: [(String, SType)] -> [(String, SType)] -> [CheckResult]
checkContext left right = [CheckResult name (check name t) | (name,t) <- left]
  where
    specifications = Map.fromList right
    check name t = case Map.lookup name specifications of
      Nothing -> NoSpecification
      Just s -> case validateType t >> validateType s of
        Left e -> IllTyped e
        Right () | subtype t s -> Holds
                 | otherwise -> Violates t s

allHold :: [CheckResult] -> Bool
allHold = all ((== Holds) . crVerdict)

reportLine :: CheckResult -> String
reportLine (CheckResult name v) = case v of
  Holds          -> "  " ++ name ++ " : OK  (inferred <= specified)"
  NoProcess      -> "  " ++ name ++ " : FAILED  (no matching process definition)"
  NoSpecification -> "  " ++ name ++ " : FAILED  (no matching type specification)"
  IllTyped e     -> "  " ++ name ++ " : ERROR  (" ++ e ++ ")"
  Violates ti ts -> "  " ++ name ++ " : FAILED  (inferred type is not a subtype of the specified type)\n"
                    ++ "        inferred:  " ++ pretty ti ++ "\n"
                    ++ "        specified: " ++ pretty ts
