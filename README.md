# Artifact for "Model-Checking Probabilistic Multiparty Session Types"

This is the artifact for POPL paper submission **#484**, "Model-Checking
Probabilistic Multiparty Session Types". It should reproduce:

- **Table 1:** inference, translation, model-checking and end-to-end timings.
- **Figure 12:** verification times and deadlock-freedom probabilities for
  concrete sessions and their typing contexts.

The artifact contains two tools for probabilistic multiparty sessions:

- **PROMT** a prototype implementation of type inference,
  infers local session types from processes,
  checks processes against type specifications,
  and checks subtyping between type contexts.
- **Prose** translates type contexts to PRISM and checks safety,
  deadlock-freedom and liveness.

## Requirements and installation

We support the installation of our artifact either through Docker or natively.

### Docker (recommended)

Install and start Docker for your host:

- **Linux (x86-64 or ARM64):** install [Docker Engine](https://docs.docker.com/engine/install/).
- **macOS (Intel or Apple Silicon):** install and start
  [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/).

Then, build the image and enter its shell from this directory:

```sh
docker build -t promt-prose .
docker run -it --name artifact promt-prose
```

The shell starts in `/opt/artifact`, containing both projects, examples and
scripts. All subsequent commands in this README run from that directory,
unless marked as host commands. The default **runtime image** includes the
compiled `promt` and `prose` tools, PRISM, Java, Python plotting dependencies,
source files and examples.

To also build an image for modifying and recompiling the tools:

```sh
docker build --target builder -t promt-prose-builder .
docker run -it --name artifact-builder promt-prose-builder
```

This optional image includes GHC, Cabal, OCaml, opam and Dune. Inside it, rebuild
with `(cd promt && cabal build exe:promt --offline)` or
`(cd prose && dune build bin/main.exe)`.

The tools are built with GHC 9.6.7, Cabal 3.12.1.0, OCaml 5.2.0, opam 2.5.2
and Dune 3.23.1. Both images include PRISM 4.10.1 and Java 17.

### Native installation

See [NATIVE-INSTALL.md](NATIVE-INSTALL.md) for Linux and macOS setup instructions,
including the compilers, PRISM and plotting dependencies.

## Sanity-check instructions

The following walkthrough exercises all five supported commands of the tool, namely;
`infer`, `typecheck`, `subtype`, `verify`, `model-check`
using the recursive process from Section 6.3 of the paper.
Run these commands from the artifact root.

### 1. Infer the paper example

`examples/ex-6-3.promt` assigns the paper's process `P` to participant `p`:

```text
p = mu X . q ! m . flip 0.5 (X, r ! m . end)
```

First print its inferred type:

```sh
./run.py infer examples/ex-6-3.promt
```

The result should be the paper's `T_inf` (up to recursion-variable names and formatting):

```text
p : (+) { q ! 1.0 : m . mu t .
      (+) { q ! 0.5 : m . t, r ! 0.5 : m . end } }
```

We can save the result into a file for the next steps:

```sh
mkdir -p results
./run.py infer examples/ex-6-3.promt -o results/ex-6-3-inferred.ctx
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

Check that `T_inf <= T_spec`:

```sh
./run.py subtype results/ex-6-3-inferred.ctx examples/ex-6-3.ctx
```

Expected output:

```text
  p : OK  (inferred <= specified)
```

### 3. Typecheck the process against the specification

```sh
./run.py typecheck examples/ex-6-3.promt examples/ex-6-3.ctx
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

Run inference followed by model checking with:

```sh
./run.py verify examples/ex-6-3-session.promt
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

### 5. Model check the exported context

The same pipeline can be split into two steps, inferring the type and exporting it
to a file, before model-checking the result:

```sh
./run.py infer examples/ex-6-3-session.promt -o results/ex-6-3-session.ctx
./run.py model-check results/ex-6-3-session.ctx
```

This should give the same results as before.

PRISM's numeric formatting may vary by version. For an example whose safety
property fails, run `./run.py model-check prose/examples/unsafe.ctx`;
it reports `false`.

### Check all example specifications

Every `.promt` file has an adjacent `.ctx` specification:

```sh
for source in examples/*.promt; do
  ./run.py typecheck "$source" "${source%.promt}.ctx" || exit 1
done
```

All participant verdicts should be `OK`.

### 6. Compare sessions and contexts, and view the plots

To check the plotting software runs properly, run the first three cases 
of the Figure 12 "sessions vs. typing-context" comparison (roughly one minute):

```sh
./compare-session-types.sh 3
```

The script prints one row as each case finishes.
On our machine, we have measured the following results (up to rounding),
though the timings may differ based on the machine.

| `n` | Participants | Session deadlock freedom | Session time (s) | Context lower bound | Context time (s) |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 3 | 0.7 | 1.669 | 0.7 | 0.401 |
| 2 | 4 | 0.49 | 1.650 | 0.35 | 0.389 |
| 3 | 5 | 0.343 | 1.639 | 0.175 | 0.390 |

Generate plots from the resulting CSV:

```sh
CSV=$(/bin/ls -t prose/experiments/results/factorial_*.csv | head -n 1)
MPLBACKEND=Agg python3 prose/experiments/plot_factorial_results.py "$CSV" --save-pdf
```

This should report three successful session measurements and three successful
context measurements, and write `factorial_probabilities.pdf` and
`factorial_times.pdf`. Open both files to check that the plots can be viewed:

```sh
# Native macOS:
open factorial_probabilities.pdf factorial_times.pdf

# Native Linux with a graphical desktop:
xdg-open factorial_probabilities.pdf
xdg-open factorial_times.pdf
```

With Docker, first copy the PDFs out from a **host terminal**:

```sh
docker cp artifact:/opt/artifact/factorial_probabilities.pdf .
docker cp artifact:/opt/artifact/factorial_times.pdf .
```

Then check they display correctly using your host's PDF viewer.

## Reproducing the experiments

This section describes the steps needed to reproduce the experiments conducted in the paper.
We expect all probability results to be identical up to floating-point rounding. The
runtime measurements may vary depending on the machine, but should exhibit similar trends.

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

This defaults to 30 timed runs per measurement, after discarding one warmup run.
Values are milliseconds, reported as **mean ± standard error**, excluding any
build or warmup times.
Add `--latex` to print the table in LaTeX format.

| Column | Description |
| --- | --- |
| Inference | One PROMT invocation, including startup, parsing, inference and type formatting. |
| Translation | Prose parsing and translation, excluding WASL. As described in the paper, each data point is a mean of 100 consecutive runs.|
| WASL | Prose's weak-almost-sure-livelock computation. |
| Safety / DF / Liveness | Separate PRISM invocations for the three properties. |
| End-to-end | `run.py verify`: tool startup, inference, context handoff, translation including WASL, and one PRISM invocation checking all three properties. |


### Factorial sessions versus type contexts

This experiment reproduces Figure 12 of the paper, comparing the cost of
model checking factorial sessions directly against their typing contexts,
and the resulting deadlock-freedom probabilities and lower bounds.
See Appendix E.7 for the processes and types.

```sh
./compare-session-types.sh         # full experiment: n = 1, ..., 30
```

The launcher delegates to `prose/experiments/factorials.sh`. For each `n`,
Prose's generators produce a concrete `.sess` file and a `.ctx` file, which are
model checked separately. PROMT inference is not involved.
There are **`n + 2` participants** (`w0`, ..., `wn`, and `dummy`), computing **`(n - 1)!`**
along the successful execution path.

Results are saved to `prose/experiments/results/factorial_<timestamp>.csv`.
Times are mean PRISM verification times in
seconds over ten runs, excluding translation.

On our machine, the full experiment **TODO Aleks**

To plot the most recent CSV:

```sh
CSV=$(/bin/ls -t prose/experiments/results/factorial_*.csv | head -n 1)
MPLBACKEND=Agg python3 prose/experiments/plot_factorial_results.py "$CSV" --save-pdf
```

This writes `factorial_probabilities.pdf` and `factorial_times.pdf` in the
current directory.
View them as described in sanity check 6. To display plots interactively,
omit both `MPLBACKEND=Agg` and `--save-pdf` on a system with a graphical display.

## Licence

The PROMT/Prose sources are released under the [MIT licence](LICENSE).
Third-party tools, such as PRISM, retain their own licences.

## Additional artifact description

### File formats

Here `p`, `l`, `x`, `t` and `w` denote participants, labels, value variables,
recursion variables and probabilities, respectively.
We write `[...]` for optional components, and `(...)*` for repetition.

#### PROMT processes (`.promt`)

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
Here `n` is a nonnegative `Int` literal.
Flips require `0 < w < 1`, using decimals or fractions such as `1/3`.

#### Local type contexts (`.ctx`)

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
Probabilities in probabilistic choice must be positive and sum to one.
Recursion must be bound and guarded.

### Directory structure

```text
run.py                        infer, typecheck, subtype, model-check and verify
benchmark.py                  combined timing table and raw samples
compare-session-types.sh      compare session and type-context model checking
Dockerfile, docker/           image build, dependencies and container checks
LICENSE                       MIT licence
examples/
  *.promt                     process definitions for paper benchmarks and examples
  *.ctx                       type specifications for paper benchmarks and examples
promt/
  app/                        PROMT command-line interface
  src/Frontend/               parser for process and type-context
  src/Syntax/                 process syntax, binding and well-formedness
  src/Typing/                 graph inference, joins, merging and subtyping
  src/Output/                 .ctx pretty-printing
prose/
  bin/, lib/                  Prose command-line interface and implementation
  examples/                   type contexts, concrete sessions and generators
  experiments/                scripts for experiments and plotting
  experiments/results/        generated factorial CSV files
  test/                       end-to-end testcases for Prose
results/                      optional output directory used in this README
```
