# Prose
Prose is a compiler from sub-**pro**babilistic multiparty **se**ssion types into [PRISM](https://www.prismmodelchecker.org/), which enables model checking of probabilitic properties on the types.

## Getting started
### Prerequisites
* [OCaml and `opam`](https://ocaml.org/install)
* [Dune](https://dune.build/install)
* [PRISM](https://www.prismmodelchecker.org/manual/InstallingPRISM/Instructions)

Ensure that the location of your `prism` executable is in your `PATH`.

### Usage
To verify probabilistic properties (e.g. safety and deadlock-freedom), run `dune exec prose -- verify [path/to/file.ctx]`.

To see the translated PRISM model and property file, run `dune exec prose -- output [path/to/file.ctx]`. You can also output the model and properties into a file using the flags `-o [filename.prism]` and `-p [filename.props]`, respectively.

For examples of session types, see [examples/](examples/).

### Testing
`dune test test/run-examples.t` (alternatively, just `dune test`)

This runs Prose on every file in the [examples/](examples/) directory, and compares both the PRISM output and the property verification output against the expected output. If they don't match, a `diff` listing of the changes are shown. If the new changes are correct, the diff can be applied automatically via `dune promote`.

## Contributing
TODO
