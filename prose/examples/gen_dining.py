#!/usr/bin/env python3
import sys

def fork(j, n):
    # fork j is shared by philosopher j (first branch) and philosopher (j-1) mod n
    a = f"p{j}"
    b = f"p{(j - 1) % n}"

    def branch(x, y):
        return (f"  {x} ? pick . (+) {{ {x} ! 1.0 : free .\n"
                f"    mu s. & {{\n"
                f"      {x} ? drop . t,\n"
                f"      {y} ? pick . (+) {{ {y} ! 1.0 : notFree . s }}\n"
                f"    }}}}")

    return (f"f{j} : mu t. & {{\n"
            f"{branch(a, b)},\n"
            f"{branch(b, a)}\n"
            f"}}\n")

def philosopher(i, n):
    # philosopher i picks up forks a = f_i and b = f_{(i+1) mod n};
    # with probability 0.5 it tries a first, otherwise b first
    a = f"f{i}"
    b = f"f{(i + 1) % n}"

    def eat_or_retreat(first, second, indent):
        p = " " * indent
        return (f"{p}(+) {{ {second} ! 1.0 : pick . & {{\n"
                f"{p}  {second} ? free .\n"
                f"{p}    (+) {{ q ! 1.0 : eat . (+) {{ {second} ! 1.0 : drop . (+) {{ {first} ! 1.0 : drop . t }}}}}},\n"
                f"{p}  {second} ? notFree .\n"
                f"{p}    (+) {{ {first} ! 1.0 : drop . t }}\n"
                f"{p}}}}}")

    def branch(first, second):
        return (f"  {first} ! 0.5 : pick . & {{\n"
                f"    {first} ? free .\n"
                f"{eat_or_retreat(first, second, 6)},\n"
                f"    {first} ? notFree .\n"
                f"      mu s. (+) {{ {first} ! 1.0 : pick . & {{\n"
                f"        {first} ? free .\n"
                f"{eat_or_retreat(first, second, 10)},\n"
                f"        {first} ? notFree . s\n"
                f"      }}}}\n"
                f"  }}")

    return (f"p{i} : mu t. (+) {{\n"
            f"{branch(a, b)},\n"
            f"{branch(b, a)}\n"
            f"}}\n")

def observer(n):
    eats = ",\n".join(f"  p{i} ? eat . t" for i in range(n))
    return f"q : mu t. & {{\n{eats}\n}}\n"

def generate(n):
    if n < 2:
        raise ValueError("need at least 2 philosophers")
    parts = [fork(j, n) for j in range(n)]
    parts += [philosopher(i, n) for i in range(n)]
    parts.append(observer(n))
    return "\n".join(parts)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(1)

    try:
        n = int(sys.argv[1])
    except ValueError:
        sys.exit(1)
    print(generate(n), end="")
