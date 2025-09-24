#!/usr/bin/env python3
import sys

def generate_factorial_context(n):
    if n < 1:
        return ""

    lines = []

    # First worker (w0) - base case
    lines.append("w0 : mu t .")
    lines.append("     w1 & req . w1 (+) { 0.7 : res(Int) . t, 0.3 : err . t }")
    lines.append("")

    # Middle workers (w1 to w(n-1)) - compute factorial numbers
    for i in range(1, n):
        curr_worker = f"w{i}"
        prev_worker = f"w{i-1}"
        next_worker = f"w{i+1}"

        lines.append(f"{curr_worker} : mu t . {next_worker} & req .")
        lines.append(f"            {prev_worker} (+) req .")
        lines.append(f"            {prev_worker} & {{")
        lines.append(f"               res(Int) . {next_worker} (+) {{ 0.5 : res(Int) . t, 0.3 : err . t }},")
        lines.append(f"               err . {next_worker} (+) err . t")
        lines.append("            }")
        lines.append("")

    # Last worker - queries the (n-1)th factorial number
    last_worker = f"w{n}"
    prev_worker = f"w{n-1}"

    lines.append(f"{last_worker} : {prev_worker} (+) req .")
    lines.append(f"     {prev_worker} & {{")
    lines.append("        res(Int) . mu t . dummy (+) done . t,")
    lines.append("        err . end")
    lines.append("     }")
    lines.append("")

    # Dummy worker
    lines.append(f"dummy : mu t . {last_worker} & done . t")
    lines.append("")

    return "\n".join(lines)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(1)

    try:
        n = int(sys.argv[1])
        print(generate_factorial_context(n), end='')
    except ValueError:
        sys.exit(1)
