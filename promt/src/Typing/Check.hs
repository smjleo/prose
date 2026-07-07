{-# LANGUAGE LambdaCase #-}

-- | Checking a process against a user-specified type.
-- > infer (normalize impl)  <=  specified
-- i.e. the process's (already normal-form) inferred type must be a subtype of
-- the specified type.
module Typing.Check
  ( CheckResult(..)
  , Verdict(..)
  , runChecks
  , allHold
  , reportLine
  ) where

import Normalize.Passes  (normalizeE)
import Typing.Infer      (infer)
import Typing.Subtype    (subtype)
import Typing.Types      (SType)
import Typing.Pretty     (pretty)
import Frontend.Parser   (Decl(..))

-- | Outcome of checking one @name : type@ specification.
data Verdict
  = Holds                       -- ^ inferred <= specified
  | Violates SType SType        -- ^ inferred is NOT a subtype of specified
  | NoProcess                   -- ^ a spec with no matching @name = process@
  | IllTyped String             -- ^ the process failed to type
  deriving (Eq, Show)

data CheckResult = CheckResult
  { crName    :: String
  , crVerdict :: Verdict
  } deriving (Eq, Show)

-- | Run every @name : type@ specification against its @name = process@.
runChecks :: [Decl] -> [CheckResult]
runChecks ds =
  [ CheckResult name (check name spec) | Spec name spec <- ds ]
  where
    defs = [ (n, p) | Def n p <- ds ]
    check name spec =
      case lookup name defs of
        Nothing   -> NoProcess
        Just impl ->
          case normalizeE impl of
            Left e   -> IllTyped ("process " ++ name ++ ": " ++ e)
            Right nf -> case infer nf of
              Left e   -> IllTyped ("process " ++ name ++ ": " ++ e)
              Right ti
                | subtype ti spec -> Holds
                | otherwise       -> Violates ti spec

-- | Did every specification hold? (Vacuously true when there are none.)
allHold :: [CheckResult] -> Bool
allHold = all ((== Holds) . crVerdict)

-- | Render one check result as a human-readable report line (multi-line for
-- violations, which show the inferred and specified types).
reportLine :: CheckResult -> String
reportLine (CheckResult name v) = case v of
  Holds          -> "  " ++ name ++ " : OK  (inferred <= specified)"
  NoProcess      -> "  " ++ name ++ " : SKIPPED  (no matching process definition)"
  IllTyped e     -> "  " ++ name ++ " : ERROR  (" ++ e ++ ")"
  Violates ti ts -> "  " ++ name ++ " : FAILED  (inferred type is not a subtype of the specified type)\n"
                    ++ "        inferred:  " ++ pretty ti ++ "\n"
                    ++ "        specified: " ++ pretty ts