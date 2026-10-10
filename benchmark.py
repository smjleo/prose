#!/usr/bin/env python3
"""Benchmark PROMT → ProSe → PRISM; report milliseconds as mean ± sample SEM.

ProSe stage samples come from its original Markdown CLI, rounded to 0.01 ms.
Inference and end-to-end samples use the host's high-resolution monotonic timer.
"""
import argparse
import csv
import math
from pathlib import Path
import re
import statistics
import subprocess
import sys
import tempfile
import time

sys.dont_write_bytecode = True
from artifact import adapt_context, infer, resolve_tools

METRICS = ("inference", "translation", "wasl", "safety", "df", "liveness", "end_to_end")
HEADERS = ("Inference", "Translation", "WASL", "Safety", "DF", "Liveness", "End-to-end")
PROSE_HEADERS = ("Filename", "Tran (ms)", "Wals (ms)", "Safe (ms)", "DF (ms)", "Live (ms)")
PAPER = {
    "auth": ("OAuth Protocol", 1),
    "dice": ("Knuth-Yao Dice", 2),
    "dining": ("Dining Philosophers", 2),
    "leader-election": ("Synchronised Leader Election", 2),
    "monty-hall-change": ("Monty Hall, Change", None),
    "monty-hall-stay": ("Monty Hall, Stay", None),
    "multiparty-workers": ("Multiparty Workers", 1),
    "gamblers-ruin": ("Gambler's Ruin", None),
    "rec-map-reduce": ("Recursive Map-Reduce", 1),
    "rec-two-buyers": ("Recursive Two Buyers", 1),
    "example-4-16": ("Example 4.16", None),
    "von-neumann-coin": ("Von-Neumann Coin", 2),
}
DEFAULT_BENCHMARKS = tuple(PAPER)


def sources(directory, selected=None):
    files = {p.stem: p.resolve() for p in directory.glob("*.promt") if p.is_file()}
    if selected:
        missing = set(selected) - files.keys()
        if missing:
            raise ValueError("missing benchmarks: " + ", ".join(sorted(missing)))
        files = {name: files[name] for name in selected}
    if not files:
        raise ValueError(f"no .promt benchmarks in {directory}")
    validate_names(files)
    order = {name: i for i, name in enumerate(PAPER)}
    return sorted(files.values(), key=lambda p: (order.get(p.stem, len(order)), p.stem))


def measure(command, runs, warmups, label):
    samples = []
    for i in range(warmups + runs):
        start = time.perf_counter_ns()
        result = subprocess.run(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elapsed = (time.perf_counter_ns() - start) / 1_000_000
        if result.returncode:
            raise ValueError(f"{label}: run {i + 1} exited with status {result.returncode}; "
                             "run this input with artifact.py verify to see diagnostics")
        if i >= warmups:
            samples.append(elapsed)
    return samples


def validate_names(names):
    if len(names) != len(set(names)):
        raise ValueError("duplicate benchmark names")
    for name in names:
        if "|" in name or "\n" in name or "\r" in name or name != name.strip():
            raise ValueError(f"unsupported benchmark filename {name!r}: ProSe's Markdown "
                             "output cannot represent pipes, line breaks, or surrounding whitespace")


def read_prose(text, names):
    """Read one original ProSe `-n 1 -markdown` invocation, in 0.01 ms units.

    The CLI prints rounded means and population SEMs. With one iteration each
    mean is one rounded sample, and its printed SEM must be zero. We calculate
    sample SEM ourselves after collecting separate invocations. ProSe catches
    per-file exceptions, so a zero exit status alone cannot establish success.
    """
    validate_names(names)
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    if len(lines) < 3:
        raise ValueError("incomplete ProSe Markdown output")

    def cells(line):
        if not line.startswith("|") or not line.endswith("|"):
            raise ValueError(f"invalid ProSe Markdown row: {line}")
        return [cell.strip() for cell in line[1:-1].split("|")]

    if cells(lines[0]) != list(PROSE_HEADERS):
        raise ValueError("ProSe returned an unexpected Markdown header")
    if cells(lines[1]) != [":---", *(["---:"] * 5)]:
        raise ValueError("ProSe returned an unexpected Markdown separator")
    result = {}
    row_end = 2
    while row_end < len(lines) and lines[row_end].startswith("|"):
        row = cells(lines[row_end])
        row_end += 1
        if len(row) != 6:
            raise ValueError(f"invalid ProSe row: expected filename and five timing columns: {row}")
        filename = row[0]
        if not filename.endswith(".ctx") or filename[:-4] not in names:
            raise ValueError(f"unexpected ProSe context: {filename}")
        name = filename[:-4]
        if name in result:
            raise ValueError(f"duplicate ProSe context: {filename}")
        metrics = {}
        try:
            for metric, cell in zip(METRICS[1:-1], row[1:]):
                ms, sem = (float(value.strip()) for value in cell.split("±"))
                if not math.isfinite(ms) or ms < 0 or not math.isfinite(sem) or sem != 0:
                    raise ValueError("expected a finite nonnegative single sample with zero SEM")
                metrics[metric] = ms
        except ValueError as error:
            raise ValueError(f"invalid ProSe sample: {row}") from error
        result[name] = metrics
    footer = "\n".join(lines[row_end:])
    if not re.fullmatch(r'\(\s*"benchmark complete with skipped files"\s*'
                        r'\(\s*skipped\s*\(\s*\)\s*\)\s*\)', footer):
        raise ValueError("ProSe reported skipped files or an invalid completion footer: "
                         + (footer or "<missing>"))
    missing = set(names) - result.keys()
    if missing:
        raise ValueError("missing ProSe contexts: " + ", ".join(sorted(missing)))
    return result


def prose_samples(prose, contexts, names, runs, batch):
    validate_names(names)
    samples = {name: {metric: [] for metric in METRICS[1:-1]} for name in names}
    for i in range(runs):
        result = subprocess.run([prose, "benchmark", str(contexts), "-n", "1",
                                 "-tb", str(batch), "-markdown"],
                                text=True, encoding="utf-8", capture_output=True)
        if result.returncode:
            detail = result.stderr.strip() or result.stdout.strip()
            raise ValueError(f"ProSe benchmark run {i + 1} exited with status "
                             f"{result.returncode}:\n{detail}")
        if result.stderr:
            print(result.stderr.rstrip(), file=sys.stderr)
        try:
            measured = read_prose(result.stdout, names)
        except ValueError as error:
            raise ValueError(f"ProSe benchmark run {i + 1}: {error}") from error
        for name in names:
            for metric in METRICS[1:-1]:
                samples[name][metric].append(measured[name][metric])
    return samples


def mean_sem(samples):
    return statistics.mean(samples), statistics.stdev(samples) / math.sqrt(len(samples))


def tex_escape(text):
    escapes = {"\\": r"\textbackslash{}", "&": r"\&", "%": r"\%", "$": r"\$",
               "#": r"\#", "_": r"\_", "{": r"\{", "}": r"\}",
               "~": r"\textasciitilde{}", "^": r"\textasciicircum{}"}
    return "".join(escapes.get(c, c) for c in text)


def table(results, latex=False):
    rows = []
    notes = set()
    for name, metrics in results.items():
        title, note = PAPER.get(name, (name, None))
        if latex:
            title = tex_escape(title)
            if name == "dining":
                title += r" (Ex.~\ref{exam:diningphilo})"
            elif name == "example-4-16":
                title = r"Example~\ref{exam:mdp}"
            if note:
                notes.add(note)
                title += rf"\tnote{{{note}}}"
        cells = []
        for metric in METRICS:
            mean, sem = mean_sem(metrics[metric])
            cells.append(f"${mean:.2f} \\pm {sem:.2f}$" if latex else f"{mean:.2f} ± {sem:.2f}")
        rows.append([title, *cells])
    if latex:
        lines = ["% Milliseconds: mean and sample standard error over independent timed runs.",
                 "% ProSe stage samples are rounded to 0.01 ms by its original Markdown CLI.",
                 r"\begin{threeparttable}", r"\begin{tabular}{l|c|c|c|c|c|c|c}",
                 " & ".join(rf"\textsf{{\textbf{{{h}}}}}" for h in ("Typing context", *HEADERS)) + r" \\",
                 r"\hline"]
        lines.extend(" & ".join(row) + r" \\" for row in rows)
        lines.append(r"\end{tabular}")
        if notes:
            lines.append(r"\begin{tablenotes}")
            if 1 in notes:
                lines.append(r"\item[1] Probabilistic variant of an example from~\cite{Scalas2019}.")
            if 2 in notes:
                lines.append(r"\item[2] Adapted from the \prism{} case studies~\cite{prismcase}.")
            lines.append(r"\end{tablenotes}")
        lines.append(r"\end{threeparttable}")
        return "\n".join(lines)
    rows.insert(0, ["Typing context", *HEADERS])
    widths = [max(len(row[i]) for row in rows) for i in range(len(rows[0]))]
    return "\n".join(" | ".join(cell.ljust(width) for cell, width in zip(row, widths)) for row in rows)


def save_samples(path, results):
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(["benchmark", "measurement", "sample", "ms"])
        for name, metrics in results.items():
            for metric in METRICS:
                for i, ms in enumerate(metrics[metric], 1):
                    writer.writerow([name, metric, i, repr(ms)])


def main(argv=None):
    root = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--examples", type=Path,
                        help="benchmark all .promt files in this directory (default: paper benchmark suite)")
    parser.add_argument("--only", nargs="+", metavar="NAME", help="benchmark only these file stems")
    parser.add_argument("--runs", "-n", type=int, default=5, help="timed runs per metric (default: 5)")
    parser.add_argument("--warmups", type=int, default=1, help="untimed runs per metric (default: 1)")
    parser.add_argument("--translation-batch", "-tb", type=int, default=100)
    parser.add_argument("--latex", "-latex", action="store_true", help="output a complete LaTeX table")
    parser.add_argument("--samples", type=Path,
                        help="also save samples as CSV (ProSe samples are rounded to 0.01 ms)")
    parser.add_argument("--promt-bin", help="use this PROMT executable without building")
    parser.add_argument("--prose-bin", help="use this ProSe executable without building")
    args = parser.parse_args(argv)
    if args.runs < 2 or args.warmups < 0 or args.translation_batch < 1:
        parser.error("runs must be at least 2; warmups nonnegative; translation batch positive")
    try:
        selected = args.only
        if args.examples is None and selected is None:
            selected = DEFAULT_BENCHMARKS
        files = sources((args.examples or root / "examples").resolve(), selected)
        promt, prose = resolve_tools(root, args.promt_bin, args.prose_bin)
        names = [source.stem for source in files]
        results = {name: {} for name in names}
        with tempfile.TemporaryDirectory(prefix="promt-benchmark-") as directory:
            contexts = Path(directory)
            for source in files:
                print(f"Inferring {source.name}...", file=sys.stderr, flush=True)
                context = contexts / (source.stem + ".ctx")
                infer(source, context, promt)
                context.write_text(adapt_context(context.read_text(encoding="utf-8")), encoding="utf-8")
                results[source.stem]["inference"] = measure(
                    [promt, "infer", str(source)], args.runs, args.warmups, source.stem + "/inference")
            if args.warmups:
                print("Warming up ProSe stages...", file=sys.stderr, flush=True)
                prose_samples(prose, contexts, names, args.warmups, args.translation_batch)
            print("Measuring ProSe stages...", file=sys.stderr, flush=True)
            stages = prose_samples(prose, contexts, names, args.runs, args.translation_batch)
            for source in files:
                results[source.stem].update(stages[source.stem])
                print(f"Measuring pipeline for {source.name}...", file=sys.stderr, flush=True)
                results[source.stem]["end_to_end"] = measure(
                    [sys.executable, str(root / "artifact.py"), "--promt-bin", promt,
                     "--prose-bin", prose, "verify", str(source)],
                    args.runs, args.warmups, source.stem + "/end-to-end")
        if args.samples:
            save_samples(args.samples, results)
        print(table(results, args.latex))
        return 0
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"Benchmark failed: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("Interrupted.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    sys.exit(main())
