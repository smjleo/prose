# PROMT

PROMT infers local types and checks specifications and subtyping. See the
[artifact README](../README.md) for setup, examples and model checking.

## Build and run

From this directory, with GHC 9.6.7 and Cabal:

```sh
cabal build exe:promt
PROMT_BIN="$(cabal list-bin exe:promt)"
"$PROMT_BIN" infer ../examples/dining.promt -o dining.ctx
"$PROMT_BIN" typecheck ../examples/dining.promt ../examples/dining.ctx
"$PROMT_BIN" subtype dining.ctx ../examples/dining.ctx
```

Without `-o`, inference prints to stdout. `typecheck` requires matching
participant sets; `subtype LEFT RIGHT` permits extra participants on the right.
Failed checks return nonzero. ProSe and PRISM are not needed.

## Process syntax (`.promt`)

Files contain distinct declarations `p = P`. `[...]` is optional and
`(...)*` denotes repetition.

```text
P ::= A (+ A)*                         receive choices use +
A ::= p ! l [<e>] . A                  send
    | p ? l [(x : B)] . A              receive
    | if e then P else P               conditional
    | flip w (P, P)                    probabilistic choice
    | mu t . P | t                     recursion
    | end | 0                          termination
    | (P) | {P}                        grouping
B ::= Unit | Bool | Int | Str | Nat
e ::= n | x | true | false | () | (e)
    | not e | succ(e) | neg(e) | e op e
op ::= + | = | == | < | > | and | or
```

`+` joins receives only; parenthesise choices under prefixes. Omitted payloads
mean `Unit`. Flips require `0 < w < 1`; recursion must be bound and guarded by
a communication. `n` is a nonnegative `Int`; use `neg(n)` for negatives.

## Type syntax (`.ctx`)

Files contain distinct declarations `p : T`.

```text
T ::= end                              termination
    | t | mu t . T                     recursion
    | (T)                              grouping
    | & {R (, R)*}                     receive choice
    | D (+ D)*                         nondeterministic choice
R ::= p ? l [(B)] . T
D ::= (+) {S (, S)*}                    probabilistic choice
S ::= p ! w : l [<B>] . T
```

Each `&` or `(+)` has nonempty branches with distinct `(p, l)` pairs.
Distribution weights are positive and sum to one. Recursion is bound and
communication-guarded. Both formats accept `(* comments *)`.

For model checking, fractions are converted to decimals and `Nat` is rejected.
Use the [shared ProSe grammar](../README.md#local-type-contexts-ctx) for
handwritten model-checking inputs, omitting grouping and explicit `Unit`.

## Source layout and AST

```text
app/Main.hs                    command-line interface
src/Frontend/Parser.hs          parsers
src/Syntax/                    process AST, binding and contractiveness
src/Typing/
  Types.hs                     type AST
  Expressions.hs               expression checking
  Inference.hs, Inference/     inference and type construction
  Relations.hs, Relations/     type graphs, joins and subtyping
  Check.hs                     specification checks
src/Output/Context.hs           .ctx rendering
```

Process constructors are `Nil`, `Sel`, `Bra`, `Flip`, `If`, `Mu` and `Var`; type
constructors are `TEnd`, `TSel`, `TBra`, `TMu` and `TRecVar`.

[MIT license](LICENSE), copyright 2026 Promt/ProSe contributors.
