#!/bin/bash
# Compare verifying the factorial session M_n directly against verifying its
# typing context, for n = 1..max_n. Usage: experiments/factorials.sh [max_n]

set -e

MAX_N=${1:-30}
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
OUTPUT_DIR="experiments/results"
OUTPUT_FILE="$OUTPUT_DIR/factorial_${TIMESTAMP}.csv"

mkdir -p "$OUTPUT_DIR"

if [[ -n ${PROSE_BIN:-} ]]; then
    if ! command -v "$PROSE_BIN" >/dev/null 2>&1; then
        echo "ProSe executable not found: $PROSE_BIN" >&2
        exit 1
    fi
    PROSE=("$PROSE_BIN")
elif command -v prose >/dev/null 2>&1; then
    PROSE=(prose)
else
    echo "Running dune build"
    dune build
    PROSE=(dune exec -- bin/main.exe)
fi

echo "n,sess_p,sess_time,ctx_p,ctx_time" > "$OUTPUT_FILE"
printf '%-4s %-14s %-24s %-16s %-19s %s\n' \
    n Participants 'Session deadlock freedom' 'Session time (s)' \
    'Context lower bound' 'Context time (s)'

# The session's state space grows with n, so once PRISM fails on a session
# (it runs out of heap space) we don't attempt the larger ones.
SESS_FAILED=0

for n in $(seq 1 "$MAX_N"); do
    CTX="$WORKDIR/fact_${n}.ctx"
    SESS="$WORKDIR/fact_${n}.sess"

    python3 examples/gen_fact_n_ctx.py $n > "$CTX"
    python3 examples/gen_fact_n_sess.py $n > "$SESS"

    SESS_P="DNF"
    SESS_TIME="DNF"
    CTX_P="DNF"
    CTX_TIME="DNF"

    if [[ $SESS_FAILED -eq 0 ]]; then
        if SESS_RESULT=$("${PROSE[@]}" verify "$SESS" -df-only 2>/dev/null) \
            && [[ $(echo "$SESS_RESULT" | wc -w) -eq 2 ]]; then
            read -r SESS_P SESS_TIME <<< "$SESS_RESULT"
        else
            SESS_FAILED=$n
        fi
    fi

    if CTX_RESULT=$("${PROSE[@]}" verify "$CTX" -df-only 2>/dev/null) \
        && [[ $(echo "$CTX_RESULT" | wc -w) -eq 2 ]]; then
        read -r CTX_P CTX_TIME <<< "$CTX_RESULT"
    fi

    echo "$n,$SESS_P,$SESS_TIME,$CTX_P,$CTX_TIME" >> "$OUTPUT_FILE"
    awk -v n="$n" -v sess="$SESS_P" -v ctx="$CTX_P" \
        -v sess_time="$SESS_TIME" -v ctx_time="$CTX_TIME" 'BEGIN {
        printf "%-4d %-14d %-24s %-16s %-19s %s\n", n, n + 2,
            (sess == "DNF" ? sess : sprintf("%.6g", sess)),
            (sess_time == "DNF" ? sess_time : sprintf("%.3f", sess_time)),
            (ctx == "DNF" ? ctx : sprintf("%.6g", ctx)),
            (ctx_time == "DNF" ? ctx_time : sprintf("%.3f", ctx_time))
    }'
done

if [[ $SESS_FAILED -ne 0 ]]; then
    echo "Session verification failed for n=$SESS_FAILED; larger sessions were skipped." >&2
fi
echo "Results saved to $OUTPUT_FILE"
