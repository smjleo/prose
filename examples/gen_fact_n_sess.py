#!/usr/bin/env python3
import sys

def generate_fibonacci_session(n):
    if n < 1:
        return ""

    lines = []

    # First worker (w0) - base case
    lines.append("w0 <- mu X . { w1?req() . flip (0.7) { H => w1!res(1) . X | T => w1!err(0) . X } }")
    lines.append("")

    # Middle workers (w1 to w(n-1)) - compute fibonacci numbers
    for i in range(1, n):
        prev_worker = f"w{i-1}"
        curr_worker = f"w{i}"
        next_worker = f"w{i+1}"

        lines.append(f"{curr_worker} <- mu X . {next_worker}?req() .")
        lines.append(f"             {prev_worker}!req() .")
        lines.append(f"             {{ {prev_worker}?res(x) .")
        lines.append("               if x < 100 then ")
        lines.append(f"                 flip (0.7) {{ H => {next_worker}!res(x * {i}) . X | T => {next_worker}!err(0) . X }} ")
        lines.append("               else")
        lines.append(f"                 flip (0.5) {{ H => {next_worker}!res(x * {i}) . X | T => {next_worker}!err(0) . X }}")
        lines.append(f"             + {prev_worker}?err(x) . {next_worker}!err(0) . X }}")
        lines.append("")

    # Last worker - queries the (n-1)th fibonacci number
    last_worker = f"w{n}"
    prev_worker = f"w{n-1}"

    lines.append(f"{last_worker} <- {prev_worker}!req() .")
    lines.append(f"  {{ {prev_worker}?res(x) . mu X . dummy!done() . X")
    lines.append(f"  + {prev_worker}?err(x) . nil }}")
    lines.append("")

    # Dummy worker
    lines.append(f"dummy <- mu X . {last_worker}?done() . X")
    lines.append("")

    return "\n".join(lines)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(1)

    try:
        n = int(sys.argv[1])
        print(generate_fibonacci_session(n), end='')
    except ValueError:
        sys.exit(1)
