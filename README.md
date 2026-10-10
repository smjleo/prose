# PROMT / ProSe artifact

This artifact contains two tools for probabilistic multiparty sessions:

- **PROMT** a prototype implementation of type inference,
  infers local session types from processes,
  checks processes against type specifications, 
  and checks subtyping between type contexts.
- **ProSe** translates type contexts to PRISM and checks safety,
  deadlock-freedom and liveness. 

The file `artifact.py`, connects inference to model checking. The
benchmark scripts reproduce the combined timing table and compare the
factorial sessions with their generated type contexts.

## Requirements and installation

### Docker

Install and start Docker for your host:

- **Linux (x86-64 or ARM64):** install [Docker Engine](https://docs.docker.com/engine/install/).
- **macOS (Intel or Apple Silicon):** install and start
  [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/).
  It runs the Linux container in a virtual machine.

On either system, build the image and enter its shell from this directory:

```sh
docker build -t promt-prose .
docker run -it --name artifact promt-prose
```

The shell starts in `/opt/artifact`, containing both projects, examples and
scripts. All subsequent commands in this README run from that directory,
unless marked as host commands. The default **runtime image** includes the
compiled `promt` and `prose` tools, PRISM, Java, Python plotting dependencies,
source files and examples. It runs the sanity checks and experiments below without further downloads;
compilers and build caches stay out of this image.

Building from source downloads and compiles dependencies in a separate builder
stage, then copies the compiled tools into the runtime image. This needs extra
disk space for build files and Docker's cache; subsequent builds reuse the cache.
Both images check the example specifications and the inference/model-checking
pipeline during construction.

To also build an image for modifying and recompiling the tools:

```sh
docker build --target builder -t promt-prose-builder .
docker run -it --name artifact-builder promt-prose-builder
```

This optional image includes GHC, Cabal, OCaml, opam and Dune. Inside it, rebuild
with `(cd promt && cabal build exe:promt --offline)` or
`(cd prose && dune build bin/main.exe)`.

Type `exit` to leave the container. Its files persist; from the host, return
with `docker start -ai artifact`. Copy generated results to the host with, for
example, `docker cp artifact:/opt/artifact/results ./results`.

The build uses the host CPU architecture by default: ARM64 on Apple Silicon or
ARM Linux, and x86-64 on Intel Macs or x86 Linux. Use that native architecture
for benchmarking. To build and run the x86-64 version on another architecture:

```sh
docker build --platform linux/amd64 -t promt-prose-amd64 .
docker run --platform linux/amd64 -it --name artifact-amd64 promt-prose-amd64
```

Docker Desktop supports this through emulation; Linux may require
[emulation setup](https://docs.docker.com/build/building/multi-platform/).
Use `linux/arm64` instead to target ARM64.

The tools are built with GHC 9.6.7, Cabal 3.12.1.0, OCaml 5.2.0, opam 2.5.2
and Dune 3.23.1. Both images include PRISM 4.10.1 and Java 17.
`toolchain.txt` records the build environment; `runtime-packages.txt` records
the packages installed in the runtime image.

### Native installation

Outside Docker, use Python 3.9 or later and install the tools needed by the
operation you wish to run:

- **Inference and type checking:** GHC and Cabal (tested with the versions above).
- **Model checking:** OCaml, Dune, Menhir, `core`, `core_unix`, `ppx_jane`, and
  PRISM with Java. Select the OCaml opam switch before running the tools.
- **Factorial experiments:** the ProSe dependencies, Bash and Python 3;
  plotting additionally requires `pandas` and `matplotlib`.

With an OCaml 5.2.0 switch selected, its dependencies can be installed using
`opam install dune menhir core core_unix ppx_jane`. Ensure `prism` is on `PATH`.
The Dockerfile records the pinned build recipe.

`artifact.py` and `benchmark.py` prefer installed `promt` and `prose`
executables on `PATH`; otherwise they build the required sibling projects.
`--promt-bin PATH` and `--prose-bin PATH` select specific executables without
building. Input and output paths are relative to the caller's directory.
The factorial launcher also uses installed `prose` (or `PROSE_BIN` when set),
falling back to Dune and the active opam environment only if needed.

## Sanity checks

The following walkthrough exercises all five supported commands of the tool, namely;
`infer`, `typecheck`, `subtype`, `verify`, `model-check`
using the recursive process from Section 6.3 of the paper, with flip probability `0.5`. 
Run these commands from the artifact root; `./artifact.py --help` lists the available modes.

### 1. Infer the paper example

`examples/ex-6-3.promt` assigns the paper's process `P` to participant `p`:

```text
p = mu X . q ! m . flip 0.5 (X, r ! m . end)
```

First print its inferred type:

```sh
./artifact.py infer examples/ex-6-3.promt
```

The result should be the paper's `T_inf` (up to recursion-variable names and formatting):

```text
p : (+) { q ! 1.0 : m . mu t .
      (+) { q ! 0.5 : m . t, r ! 0.5 : m . end } }
```

The initial send to `q` is certain; subsequent choices either repeat it with
probability `0.5` or send to `r` and terminate with probability `0.5`.
Then save it for the following checks:

```sh
mkdir -p results
./artifact.py infer examples/ex-6-3.promt -o results/ex-6-3-inferred.ctx
```

The `.ctx` format is shared by inference, specifications and model checking.

### 2. Check subtyping against a broader specification

`examples/ex-6-3.ctx` contains `T_spec`, obtained by adding a nondeterministic
alternative `q ! cancel . end` to `T_inf`:

```text
p : (+) { q ! 1.0 : m . mu t .
      (+) { q ! 0.5 : m . t, r ! 0.5 : m . end } }
    + (+) { q ! 1.0 : cancel . end }
```

Here `+` separates nondeterministic alternatives; the probabilities inside each
`(+)` still sum to one. Check that `T_inf <= T_spec`:

```sh
./artifact.py subtype results/ex-6-3-inferred.ctx examples/ex-6-3.ctx
```

Expected output:

```text
  p : OK  (inferred <= specified)
```

Reversing the two files fails: the extra `cancel` alternative is not permitted
by `T_inf`. In general, `subtype LEFT RIGHT` checks each left participant against
its counterpart on the right;

### 3. Typecheck the process against the specification

```sh
./artifact.py typecheck examples/ex-6-3.promt examples/ex-6-3.ctx
```

This infers the process's type and checks it against `T_spec`, producing the
same `p : OK` verdict without needing an intermediate file. Both files must
contain exactly the same participant names.

### 4. Verify a complete session

The process above mentions `q` and `r` but does not define them. The file
`examples/ex-6-3-session.promt` keeps `p` unchanged and adds:

```text
q = p ? m . r ? done . end
r = p ? m . q ! done . end
```

After the initial `p`--`q` communication, choosing `r` lets `r` notify `q` and
all three terminate. Choosing `q` again deadlocks: `q` is waiting for `r`,
while `r` is waiting for `p`. Thus successful termination has probability
`0.5`. Run inference followed by model checking with:

```sh
./artifact.py verify examples/ex-6-3-session.promt
```

The reported properties should be:

```text
Type safety
Result: true

Deadlock freedom (lower bound)
Result: 0.5 (exact floating point)

Liveness (lower bound)
Result: 0.5 (exact floating point)
```

For a variation, `examples/ex-6-3-session-three.promt` lets `p` send to `q`
at most three times. Now `q` notifies `r` when all three messages arrive:

```text
p = q ! m . flip 0.5 (
      q ! m . flip 0.5 (q ! m . end, r ! m . end),
      r ! m . end)
q = p ? m . p ? m . p ? m . r ! quit . end
r = p ? m . end + q ? quit . end
```

Both flips must choose `q` for everyone to terminate, with probability
`0.5 * 0.5 = 0.25`. An early send to `r` lets `p` and `r` terminate but leaves
`q` waiting for the remaining messages.

```sh
./artifact.py verify examples/ex-6-3-session-three.promt
```

Expect safety `true` and both deadlock-freedom and liveness bounds `0.25`.

### 5. Model check the exported context

The same pipeline can be split into two steps, inferring the type and exporting it
to a file, before model-checking the result:

```sh
./artifact.py infer examples/ex-6-3-session.promt -o results/ex-6-3-session.ctx
./artifact.py model-check results/ex-6-3-session.ctx
```

This gives the same three property results as `verify`: `true`, `0.5`, `0.5`.
The exported context includes all three participants.

PRISM's numeric formatting may vary by version. For an example whose safety
property fails, run `./artifact.py model-check prose/examples/unsafe.ctx`;
it reports `false`. 

### Check all example specifications

Every `.promt` file has an adjacent `.ctx` specification:

```sh
for source in examples/*.promt; do
  ./artifact.py typecheck "$source" "${source%.promt}.ctx" || exit 1
done
```

All participant verdicts should be `OK`.

## Reproducing the experiments

### Combined timing table

This section walks through how to reproduce the results presented in table 1 of the 
paper. The sessions used can all be found in `examples/`.

For a quick check of the benchmark harness:

```sh
./benchmark.py --only auth --runs 2 --warmups 0
```

It prints one row with inference, translation, WASL, safety, deadlock-freedom,
liveness and end-to-end timings. Reproduce the complete table with:

```sh
mkdir -p results
./benchmark.py --samples results/samples.csv
```

This defaults to five timed runs and one warmup per measurement. Values are milliseconds,
reported as **mean ± standard error** (`sample_stdev / sqrt(runs)`); builds and
warmups are excluded. Use `--only NAME ...` to select examples or `--runs 30`
for more repetitions (at least two are required). Add `--latex` to output a
LaTeX table instead. Progress goes to stderr.

| Column | What is measured |
| --- | --- |
| Inference | One PROMT invocation, including startup, parsing, inference and type formatting. |
| Translation | ProSe parsing and translation, excluding WASL; each sample averages 100 translations (`--translation-batch` changes this). |
| WASL | ProSe's weak-almost-sure-livelock computation. |
| Safety / DF / Liveness | Separate PRISM invocations for the three properties. |
| End-to-end | `artifact.py verify`: tool startup, inference, context handoff, translation including WASL, and one PRISM invocation checking all three properties. |

The end-to-end measurement is independent, not the sum of the other columns:
the individual property columns each start PRISM, whereas the pipeline starts
it once. Timed inference and pipeline stdout/stderr go to /dev/null;

### Factorial sessions versus type contexts

This experiment reproduces Figure 12 of the paper, comparing the cost of
model checking factorial sessions directly against their typing contexts,
and the resulting deadlock-freedom probabilities and lower bounds.

Run it directly from the artifact root:

```sh
./compare-session-types.sh 3       # small check: n = 1, 2, 3
./compare-session-types.sh         # full experiment: n = 1, ..., 30
```

The launcher delegates to `prose/experiments/factorials.sh`. For each `n`,
ProSe's generators produce a concrete `.sess` file and a `.ctx` file, which are
model checked separately; PROMT inference is not involved.
There are **`n + 2` participants** (`w0`, ..., `wn`, and `dummy`), computing **`(n - 1)!`** 
along the successful execution path.

The script prints one row as each case finishes. For the small check, expect
the probabilities below (up to rounding); the times show one local run and
will vary by machine:

| `n` | Participants | Session deadlock freedom | Session time (s) | Context lower bound | Context time (s) |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 3 | 0.7 | 1.669 | 0.7 | 0.401 |
| 2 | 4 | 0.49 | 1.650 | 0.35 | 0.389 |
| 3 | 5 | 0.343 | 1.639 | 0.175 | 0.390 |

Results are saved to `prose/experiments/results/factorial_<timestamp>.csv`:
`n,sess_p,sess_time,ctx_p,ctx_time`. Times are mean PRISM verification times in
seconds over ten runs, excluding translation. Allow a minute or so for the
small check. `DNF` marks failed or skipped measurements; after a session fails,
larger sessions are skipped while context measurements continue.

In the paper's experiment, session verification exhausted PRISM's default
1 GB Java heap for `n >= 14`; the cutoff may differ on your machine. See
Appendix E.7 for the processes and types.

To plot the most recent CSV:

```sh
CSV=$(ls -t prose/experiments/results/factorial_*.csv | head -n 1)
MPLBACKEND=Agg python3 prose/experiments/plot_factorial_results.py "$CSV" --save-pdf
```

This writes `factorial_probabilities.pdf` and `factorial_times.pdf` in the
current directory.
Use the full run for the complete curves; timings depend on your machine.
Omit `--save-pdf` to display the plots interactively when a graphical display
is available.

### Saving container results

Inside a named container, generated files remain available after leaving its
shell. From the host, copy them out, for example:

```sh
docker cp artifact:/opt/artifact/results ./results
docker cp artifact:/opt/artifact/factorial_probabilities.pdf .
docker cp artifact:/opt/artifact/factorial_times.pdf .
docker cp artifact:/opt/artifact/prose/experiments/results ./factorial-results
```

For a one-off table written directly on the host:

```sh
docker run --rm promt-prose ./benchmark.py > table.txt
```

## Licence

The PROMT/ProSe sources are released under the [MIT licence](LICENSE),
copyright 2026 Promt/ProSe contributors. Third-party tools retain their own
licences. The Docker image retains PRISM's licence notices under `/opt/prism`
and its source archive at `/opt/prism-source.tar.gz`.

## Appendix: file formats

Here `p`, `l`, `x`, `t` and `w` denote participants, labels, value variables,
recursion variables and probabilities. `[...]` is optional; `(...)*` denotes
repetition. Both formats accept `(* comments *)`.

### PROMT processes (`.promt`)

Files contain distinct declarations `p = P`.

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

Only receives combine with `+`; parenthesise choices under prefixes, e.g.
`q ! m . (r ? a . end + r ? b . end)`. Recursion must be bound and
communication-guarded. Omitted payloads mean `Unit`; received values are
scoped to their continuation.

`n` is a nonnegative `Int` literal; use `neg(n)` for negatives and parentheses
to group expressions. `Str` values can be forwarded but have no literals.
Flips require `0 < w < 1`, using decimals or fractions such as `1/3`.

### Local type contexts (`.ctx`)

Files contain distinct declarations `p : T`.

```text
T ::= end                              termination
    | t | mu t . T                     recursion
    | & {R (, R)*}                     receive choice
    | D (+ D)*                         nondeterministic choice
R ::= p ? l [(B)] . T
D ::= (+) {S (, S)*}                    probabilistic choice
S ::= p ! w : l [<B>] . T
B ::= Int | Bool | Str
```

Each `&` or `(+)` has nonempty branches with distinct `(p, l)` pairs.
Distribution weights are positive and sum to one. Recursion must be bound
and communication-guarded; omitted payloads mean `Unit`.

This syntax serves inference, checking and model checking. PROMT additionally
accepts fractions, `Nat`, grouped types and explicit `Unit`. For ProSe, use the
grammar above with decimal weights such as `0.5` or `1.0`; the driver converts
fractions but rejects `Nat` and does not remove grouping or `Unit` annotations.

## Appendix: directory structure

```text
artifact.py                   infer, typecheck, subtype, model-check and verify
benchmark.py                  combined timing table and raw samples
compare-session-types.sh      compare session and type-context model checking
Dockerfile, docker/           image build, dependencies and container checks
LICENSE                       MIT licence
examples/
  *.promt                     paper benchmarks and sanity examples
  *.ctx                       matching type specifications
promt/
  app/                        PROMT command-line interface
  src/Frontend/               process and type-context parser
  src/Syntax/                 process syntax, binding and well-formedness
  src/Typing/                 graph inference, joins, merging and subtyping
  src/Output/                 shared .ctx renderer
prose/
  bin/, lib/                  ProSe command-line interface and implementation
  examples/                   type contexts, concrete sessions and generators
  experiments/                original experiments and factorial plotting
  experiments/results/        generated factorial CSV files
  test/                       original ProSe snapshots
results/                      optional output directory used in this README
```
