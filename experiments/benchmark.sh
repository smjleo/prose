#!/bin/zsh

REPEATS=30
TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
OUTPUT_DIR="experiments/results"
OUTPUT_FILE="$OUTPUT_DIR/benchmark_${TIMESTAMP}.csv"
STATS_SCRIPT="experiments/stats.py"
FILES=$(find examples -name "*.ctx")

mkdir -p "$OUTPUT_DIR"
echo "file,runtime_ms" > "$OUTPUT_FILE"

echo "Running dune build"
dune build

benchmark() {
    local file=$1
    local basename=$(basename "$file")

    for i in {1..$REPEATS}; do
        # ideally we use `time`, but macOS only has 10us precision
        start_nano=$(gdate +%s%N)
        _build/default/bin/main.exe verify $file > /dev/null
        end_nano=$(gdate +%s%N)
        runtime=$(((end_nano - start_nano)/1000000))
        echo "$basename,$runtime" >> "$OUTPUT_FILE"
    done
}

for file in examples/*.ctx; do
    echo "Benchmarking $file"
    benchmark "$file"
done

echo "Results saved to $OUTPUT_FILE"

$STATS_SCRIPT $OUTPUT_FILE
