#!/bin/bash

# Script to collect termination probability and timing data for factorial examples
# Generates fact_n.ctx and fact_n.sess files for n=2..13, runs term-only verification,
# and outputs results to CSV format

set -e

TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
OUTPUT_DIR="experiments/results"
OUTPUT_FILE="$OUTPUT_DIR/factorial_${TIMESTAMP}.csv"

mkdir -p "$OUTPUT_DIR"

# Create CSV header
echo "n,sess_p,sess_time,ctx_p,ctx_time" > "$OUTPUT_FILE"

# Loop through n from 2 to 13
for n in {2..13}; do
    echo "Processing n=$n..."

    # Generate temporary files
    TEMP_CTX="examples/fact_${n}_temp.ctx"
    TEMP_SESS="examples/fact_${n}_temp.sess"

    # Generate files using the scripts
    python3 examples/gen_fact_n_ctx.py $n > "$TEMP_CTX"
    python3 examples/gen_fact_n_sess.py $n > "$TEMP_SESS"

    # Run term-only verification and capture results
    SESS_RESULT=$(dune exec -- bin/main.exe verify "$TEMP_SESS" -term-only)
    CTX_RESULT=$(dune exec -- bin/main.exe verify "$TEMP_CTX" -term-only)

    # Parse results (space-separated probability and time)
    SESS_P=$(echo "$SESS_RESULT" | cut -d' ' -f1)
    SESS_TIME=$(echo "$SESS_RESULT" | cut -d' ' -f2)
    CTX_P=$(echo "$CTX_RESULT" | cut -d' ' -f1)
    CTX_TIME=$(echo "$CTX_RESULT" | cut -d' ' -f2)

    # Output CSV row
    echo "$n,$SESS_P,$SESS_TIME,$CTX_P,$CTX_TIME" >> "$OUTPUT_FILE"

    # Clean up temporary files
    rm "$TEMP_CTX" "$TEMP_SESS"
done

echo "Results saved to $OUTPUT_FILE"