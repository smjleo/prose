#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

python3 -c 'import matplotlib, numpy, pandas'
gtimeout 5 gdate +%s%N >/dev/null
for source in examples/*.promt; do
    python3 artifact.py typecheck "$source" "${source%.promt}.ctx"
done
python3 - <<'PY'
from pathlib import Path
from math import isclose
import re
import subprocess
import sys
import tempfile

def run(*arguments):
    result = subprocess.run([sys.executable, "artifact.py", *map(str, arguments)],
                            text=True, capture_output=True, timeout=120)
    if result.returncode:
        sys.exit(result.stdout + result.stderr)
    return result.stdout

with tempfile.TemporaryDirectory() as directory:
    context = Path(directory) / "inferred.ctx"
    run("infer", "examples/ex-6-3.promt", "-o", context)
    print(run("subtype", context, "examples/ex-6-3.ctx"), end="")
    for name, probability in [("ex-6-3-session", 0.5),
                              ("ex-6-3-session-three", 0.25)]:
        source = f"examples/{name}.promt"
        run("infer", source, "-o", context)
        for command, input_file in [("verify", source), ("model-check", context)]:
            output = run(command, input_file)
            values = re.findall(r"^Result: (\S+)", output, re.MULTILINE)
            if (len(values) != 3 or values[0] != "true" or
                    not all(isclose(float(value), probability, abs_tol=1e-12)
                            for value in values[1:])):
                sys.exit(f"Unexpected {command} results for {name}:\n{output}")
        print(f"{name}: verify and model-check agree (true, {probability}, {probability})")
PY
