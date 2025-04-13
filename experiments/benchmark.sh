#!/bin/zsh

REPEATS=30
TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
OUTPUT_DIR="experiments/results"
OUTPUT_FILE="$OUTPUT_DIR/benchmark_${TIMESTAMP}.csv"
FILES=$(find examples -name "*.ctx")

mkdir -p "$OUTPUT_DIR"
echo "file,runtime_seconds" > "$OUTPUT_FILE"

echo "Running dune build"
dune build

benchmark() {
    local file=$1
    local basename=$(basename "$file")

    export TIMEFMT="%*E"

    for i in {1..$REPEATS}; do
        # ideally we use -f, but apparently the macOS version of /usr/bin/time doesn't have this option
        runtime=$((/usr/bin/time -p _build/default/bin/main.exe verify $file > /dev/null ) 2>&1 | awk '/real/ {print $2}')
        echo "$basename,$runtime" >> "$OUTPUT_FILE"
    done
}

for file in examples/*.ctx; do
    echo "Benchmarking $file"
    benchmark "$file"
done

echo "Results saved to $OUTPUT_FILE"
