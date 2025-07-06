# Prose
Prose is a compiler from sub-**pro**babilistic multiparty **se**ssion types into [PRISM](https://www.prismmodelchecker.org/), which enables model checking of probabilitic properties on the types.

## Getting started
### Prerequisites
* [OCaml and `opam`](https://ocaml.org/install)
* [Dune](https://dune.build/install)
* [PRISM](https://www.prismmodelchecker.org/manual/InstallingPRISM/Instructions)
* `opam install core ppx_jane`

Ensure that the location of your `prism` executable is in your `PATH`.

For the end-to-end benchmark and analysis scripts, we additionally require:
* zsh
* [Python and `pip`](https://www.python.org/downloads/)
* `pip install numpy scipy pandas`


### Usage
To verify probabilistic properties (e.g. safety and deadlock-freedom), run `dune exec prose -- verify [path/to/file.ctx]`.

To see the translated PRISM model and property file, run `dune exec prose -- output [path/to/file.ctx]`. You can also output the model and properties into a file using the flags `-o [filename.prism]` and `-p [filename.props]`, respectively.

For examples of session types, see [examples/](examples/).

### Benchmarking
There are two types of benchmarks: end-to-end and granular.

The end-to-end benchmark measures the runtime of invoking `prose`, from start to finish. This can be run using [experiments/benchmark.sh](experiments/benchmark.sh), which invokes [experiments/stats.py](experiments/stats.py) for analysis. The raw data is also placed in [experiments/results/](experiments/results/).

The granular benchmark measures the time taken for the translation and the PRISM verification of each property, all separately. This is done directly via the Prose CLI: `dune exec prose -- benchmark [path/to/dir]` runs benchmarks on all context files in the directory given. 

For example, use the [examples/](examples/) directory: `dune exec prose -- benchmark examples`.

The granular benchmark also supports LaTeX `tabular` output (to reproduce the table in the paper): `dune exec prose -- benchmark examples -latex`.

### Testing
`dune test test/run-examples.t` (alternatively, just `dune test`)

This runs Prose on every file in the [examples/](examples/) directory, and compares both the PRISM output and the property verification output against the expected output. If they don't match, a `diff` listing of the changes are shown. If the new changes are correct, the diff can be applied automatically via `dune promote`.

## Contributing
TODO
