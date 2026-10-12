# Native installation

These instructions cover Debian/Ubuntu Linux and macOS (Intel or ARM64).
The commands below should be run from the artifact root in the same terminal.

## 1. Install system dependencies

On Debian/Ubuntu:

```sh
sudo apt-get update
sudo apt-get install -y build-essential curl git m4 patch pkg-config rsync \
  unzip xz-utils bzip2 libffi-dev libgmp-dev libncurses-dev libnuma-dev \
  zlib1g-dev opam bubblewrap openjdk-17-jre-headless \
  python3 python3-pip python3-venv
```

On macOS, install the Xcode Command Line Tools (`xcode-select --install`) and
[Homebrew](https://brew.sh/).
Then run:

```sh
brew install opam python@3.12 openjdk@17 pkg-config gmp
export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$(brew --prefix python@3.12)/libexec/bin:$PATH"
```

Use a native terminal on Apple Silicon so that Java and PRISM are using the same architecture.

## 2. Install the compilers and libraries

Install [GHCup](https://www.haskell.org/ghcup/install/), and use the following
GHC and Cabal versions:

```sh
ghcup install ghc 9.6.7
ghcup set ghc 9.6.7
ghcup install cabal 3.12.1.0
ghcup set cabal 3.12.1.0
```

Then, create an OCaml switch and install the dependencies required for Prose.

(if it can't find the versions indicated below when running `opam install` 
 then do an `opam update` and retry)

```sh
opam init --bare --no-setup -y
opam switch create promt-prose ocaml-base-compiler.5.2.0 -y
eval "$(opam env --switch=promt-prose --set-switch)"
opam install -y dune.3.23.1 menhir.20260209 core.v0.17.2 core_unix.v0.17.1 ppx_jane.v0.17.0
```

## 3. Install PRISM

Download [PRISM 4.10.1](https://github.com/prismmodelchecker/prism/releases/tag/v4.10.1)
for your OS and processor (Linux/macOS, x86/ARM).
See the [PRISM installation guide](https://www.prismmodelchecker.org/manual/InstallingPRISM/Instructions)
for platform-specific help.

And remember to add prism to the PATH variable in your terminal.

## 4. Build the tools and install plotting support

From the artifact root:

```sh
(cd promt && cabal --config-file=/dev/null build exe:promt --offline \
  --constraint='containers == 0.6.7')
(cd prose && opam exec -- dune build bin/main.exe)
mkdir -p "$HOME/.local/bin"
install -m 755 "$(cd promt && cabal --config-file=/dev/null list-bin exe:promt)" "$HOME/.local/bin/promt"
install -m 755 prose/_build/default/bin/main.exe "$HOME/.local/bin/prose"
export PATH="$HOME/.local/bin:$PATH"
python3 -m venv .venv
. .venv/bin/activate
python3 -m pip install pandas matplotlib
```

The benchmark scripts find both compiled tools on `PATH`, though they can be overriden using the flags `--promt-bin` and `--prose-bin`.
In later terminals, restore these PATH settings, select the OCaml switch with
`eval "$(opam env --switch=promt-prose --set-switch)"`, and activate `.venv` again.

Continue with the [README sanity checks](README.md#sanity-check-instructions).
