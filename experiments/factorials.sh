#!/bin/bash

set -e

TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
OUTPUT_DIR="experiments/results"
OUTPUT_FILE="$OUTPUT_DIR/factorial_${TIMESTAMP}.csv"

mkdir -p "$OUTPUT_DIR"

echo "n,sess_p,sess_time,sess_upper_p,sess_upper_time,ctx_p,ctx_time" > "$OUTPUT_FILE"

for n in {2..30}; do
    echo "Processing n=$n..."

    TEMP_CTX="examples/fact_${n}_temp.ctx"
    TEMP_SESS="examples/fact_${n}_temp.sess"

    python3 examples/gen_fact_n_ctx.py $n > "$TEMP_CTX"
    python3 examples/gen_fact_n_sess.py $n > "$TEMP_SESS"

    SESS_P="DNF"
    SESS_TIME="DNF"
    SESS_UPPER_P="DNF"
    SESS_UPPER_TIME="DNF"
    CTX_P="DNF"
    CTX_TIME="DNF"

    if SESS_RESULT=$(dune exec -- bin/main.exe verify "$TEMP_SESS" -term-only 2>/dev/null); then
        if [[ $(echo "$SESS_RESULT" | wc -w) -eq 2 ]]; then
            SESS_P=$(echo "$SESS_RESULT" | cut -d' ' -f1)
            SESS_TIME=$(echo "$SESS_RESULT" | cut -d' ' -f2)
        fi
    fi

    if SESS_UPPER_RESULT=$(dune exec -- bin/main.exe verify "$TEMP_SESS" -term-only -upper 2>/dev/null); then
        if [[ $(echo "$SESS_UPPER_RESULT" | wc -w) -eq 2 ]]; then
            SESS_UPPER_P=$(echo "$SESS_UPPER_RESULT" | cut -d' ' -f1)
            SESS_UPPER_TIME=$(echo "$SESS_UPPER_RESULT" | cut -d' ' -f2)
        fi
    fi

    if CTX_RESULT=$(dune exec -- bin/main.exe verify "$TEMP_CTX" -term-only 2>/dev/null); then
        if [[ $(echo "$CTX_RESULT" | wc -w) -eq 2 ]]; then
            CTX_P=$(echo "$CTX_RESULT" | cut -d' ' -f1)
            CTX_TIME=$(echo "$CTX_RESULT" | cut -d' ' -f2)
        fi
    fi

    echo "$n,$SESS_P,$SESS_TIME,$SESS_UPPER_P,$SESS_UPPER_TIME,$CTX_P,$CTX_TIME" >> "$OUTPUT_FILE"

    rm "$TEMP_CTX" "$TEMP_SESS"
done

echo "Results saved to $OUTPUT_FILE"