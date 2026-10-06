#!/bin/bash
# Compare verifying the factorial session M_n directly against verifying its
# typing context, for n = 2..max_n. Usage: experiments/factorials.sh [max_n]

set -e

MAX_N=${1:-30}
WORKDIR=$(mktemp -d)
TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
OUTPUT_DIR="experiments/results"
OUTPUT_FILE="$OUTPUT_DIR/factorial_${TIMESTAMP}.csv"

mkdir -p "$OUTPUT_DIR"

echo "Running dune build"
dune build

echo "n,sess_p,sess_time,ctx_p,ctx_time" > "$OUTPUT_FILE"

# The session's state space grows with n, so once PRISM fails on a session
# (it runs out of heap space) we don't attempt the larger ones.
SESS_FAILED=0

for n in $(seq 2 "$MAX_N"); do
    echo "Processing n=$n..."

    CTX="$WORKDIR/fact_${n}.ctx"
    SESS="$WORKDIR/fact_${n}.sess"

    python3 examples/gen_fact_n_ctx.py $n > "$CTX"
    python3 examples/gen_fact_n_sess.py $n > "$SESS"

    SESS_P="DNF"
    SESS_TIME="DNF"
    CTX_P="DNF"
    CTX_TIME="DNF"

    if [[ $SESS_FAILED -eq 0 ]]; then
        if SESS_RESULT=$(dune exec -- bin/main.exe verify "$SESS" -df-only 2>/dev/null) \
            && [[ $(echo "$SESS_RESULT" | wc -w) -eq 2 ]]; then
            read -r SESS_P SESS_TIME <<< "$SESS_RESULT"
        else
            echo "Session verification failed for n=$n, skipping larger sessions"
            SESS_FAILED=1
        fi
    fi

    if CTX_RESULT=$(dune exec -- bin/main.exe verify "$CTX" -df-only 2>/dev/null) \
        && [[ $(echo "$CTX_RESULT" | wc -w) -eq 2 ]]; then
        read -r CTX_P CTX_TIME <<< "$CTX_RESULT"
    fi

    echo "$n,$SESS_P,$SESS_TIME,$CTX_P,$CTX_TIME" >> "$OUTPUT_FILE"
done

rm -r "$WORKDIR"

echo "Results saved to $OUTPUT_FILE"
