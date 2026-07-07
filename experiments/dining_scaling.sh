#!/bin/zsh
# Sweep dining philosophers size n upward until verification times out or
# runs out of memory. Usage: experiments/dining_scaling.sh [timeout_s] [max_n]

TIMEOUT=${1:-300}
MAX_N=${2:-12}
WORKDIR=${DINING_WORKDIR:-$(mktemp -d)}
TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
OUTPUT_DIR="experiments/results"
OUTPUT_FILE="$OUTPUT_DIR/dining_scaling_${TIMESTAMP}.csv"

mkdir -p "$OUTPUT_DIR"
echo "n,status,runtime_s" > "$OUTPUT_FILE"

echo "Running dune build"
dune build

for n in $(seq 3 $MAX_N); do
    ctx="$WORKDIR/dining_$n.ctx"
    log="$WORKDIR/dining_$n.log"
    python3 examples/gen_dining.py $n > "$ctx"

    echo "Verifying n=$n (timeout ${TIMEOUT}s)"
    start_nano=$(gdate +%s%N)
    gtimeout $TIMEOUT dune exec prose -- verify "$ctx" > "$log" 2>&1
    code=$?
    end_nano=$(gdate +%s%N)
    runtime=$(printf "%.1f" $(((end_nano - start_nano)/1000000000.0)))

    if [[ $code -eq 124 ]]; then
        echo "n=$n TIMED OUT after ${TIMEOUT}s"
        echo "$n,timeout,$runtime" >> "$OUTPUT_FILE"
        break
    elif grep -qi "outofmemory\|out of memory" "$log"; then
        echo "n=$n OUT OF MEMORY after ${runtime}s"
        echo "$n,oom,$runtime" >> "$OUTPUT_FILE"
        break
    elif [[ $code -ne 0 ]]; then
        echo "n=$n FAILED (exit $code) after ${runtime}s; last log lines:"
        tail -5 "$log"
        echo "$n,error,$runtime" >> "$OUTPUT_FILE"
        break
    fi

    echo "n=$n ok in ${runtime}s"
    echo "$n,ok,$runtime" >> "$OUTPUT_FILE"
done

echo "Results saved to $OUTPUT_FILE"
echo "Logs in $WORKDIR"
