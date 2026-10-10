#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 [max_n]"
    echo "Compare model checking of factorial sessions and typing contexts for n=1..max_n (default: 30)."
    echo "Results are written to prose/experiments/results/factorial_<timestamp>.csv."
}

if [[ $# -eq 1 && ($1 == --help || $1 == -h) ]]; then
    usage
    exit 0
fi
if [[ $# -gt 1 || ! ${1-30} =~ ^[1-9][0-9]*$ ]]; then
    usage >&2
    echo "max_n must be a positive integer." >&2
    exit 2
fi

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd -- "$root/prose"
if [[ -z ${PROSE_BIN:-} ]] && ! command -v prose >/dev/null 2>&1 \
    && command -v opam >/dev/null 2>&1; then
    exec opam exec -- bash experiments/factorials.sh "${1-30}"
fi
exec bash experiments/factorials.sh "${1-30}"
