# Native installation

These instructions cover Debian/Ubuntu Linux and macOS (Intel or ARM64).
Run the project commands from the artifact root, in the same terminal.

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
[Homebrew](https://brew.sh/), following its instructions to add `brew` to `PATH`.
Then run:

```sh
brew install opam python@3.12 openjdk@17 pkg-config gmp
export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$(brew --prefix python@3.12)/libexec/bin:$PATH"
```

Use a native terminal on Apple Silicon so Java and PRISM use the same architecture.

## 2. Install the compilers and libraries

Install [GHCup](https://www.haskell.org/ghcup/install/), then select the tested
GHC and Cabal versions:

```sh
ghcup install ghc 9.6.7
ghcup set ghc 9.6.7
ghcup install cabal 3.12.1.0
ghcup set cabal 3.12.1.0
```

Create an OCaml switch and install Prose's dependencies 

```sh
opam init --bare --no-setup -y
opam switch create promt-prose ocaml-base-compiler.5.2.0 -y
eval "$(opam env --switch=promt-prose --set-switch)"
opam install -y dune.3.23.1 menhir.20260209 \
  core.v0.17.2 core_unix.v0.17.1 ppx_jane.v0.17.0
```

## 3. Install PRISM

Download [PRISM 4.10.1](https://github.com/prismmodelchecker/prism/releases/tag/v4.10.1)
for your OS and processor (Linux/macOS, x86/ARM). Extract it to a permanent
location, run `./install.sh` from the extracted directory, and add its `bin`
directory to `PATH`. Check that `prism -version` works; Java 17 must also be
on `PATH`. See the [PRISM installation guide](https://www.prismmodelchecker.org/manual/InstallingPRISM/Instructions)
for platform-specific help.

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

PROMT builds offline using GHC's bundled libraries. The scripts find both
compiled tools on `PATH`; `--promt-bin` and `--prose-bin` can override them.
In later terminals, restore these PATH settings, select the OCaml switch with
`eval "$(opam env --switch=promt-prose --set-switch)"`, and activate `.venv` again.

Continue with the [README sanity checks](README.md#sanity-check-instructions).
