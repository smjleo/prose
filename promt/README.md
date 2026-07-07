# PROMT Artifact

This repository contains the implementation of the PROMT process type inference and
checking tool used for the paper artifact.

The tool parses PROMT process definitions, infers their types, and optionally checks
the inferred type against a user-provided type specification.

## Tested Environment

This artifact has been tested with:

```text
GHC:            9.6.7
cabal-install:  3.12.1.0
Cabal library:  3.12.1.0
```

The project only depends on the standard `base` package and `containers`.

## Building

From the root of the repository, run:

```bash
cabal update
cabal build all
```

## Running Tests

Run the test suite with:

```bash
cabal test all
```

## Running the Tool

The executable is called `promt`.

Run the tool on an input file with:

```bash
cabal run promt -- file.promt [--prose]
```

or, after building or installing the executable:

```bash
promt file.promt [--prose]
```

By default, `promt` outputs inferred types in a human-readable pretty-printed
format.

With the optional `--prose` flag, `promt` outputs types in the input format
expected by the Prose model checker.

## Input Format

A `.promt` file contains a list of participant/process definitions.

Each definition has the form:

```text
name = process
```

Optionally, a type specification may be provided on the following line:

```text
name : type
```

If no type specification is provided, `promt` only performs type inference.

If a type specification is provided, `promt` infers the type of the process and
checks the inferred type against the given specification.

Comments are written using `(* ... *)`.

## Example

```text
(* branching subtype: impl handles a AND b; spec only requires a *)
server = r ? a . end + r ? b . end
server : & { r ? a . end }

(* a probabilistic sender checked against an exact distribution *)
coin = flip 0.5 ( s ! heads . end , s ! tails . end )
coin : (+) { s ! 0.5 : heads . end , s ! 0.5 : tails . end }
```

In this example, `server` is checked against the specification:

```text
& { r ? a . end }
```

The process `coin` is checked against the probabilistic output type:

```text
(+) { s ! 0.5 : heads . end , s ! 0.5 : tails . end }
```

If either the `server : ...` or `coin : ...` line were omitted, `promt` would
infer and print the corresponding type without checking it against a
specification.
