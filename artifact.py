#!/usr/bin/env python3
"""Infer, typecheck, compare and model-check PROMT/ProSe contexts.

Use installed executables on PATH, or build only the required sibling projects.
Explicit --promt-bin/--prose-bin overrides select an executable without building.
"""

import argparse
from decimal import Decimal
from fractions import Fraction
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


class ArtifactError(ValueError):
    """A tool failure suitable for displaying without a traceback."""


def _executable(argument, label):
    """Resolve a caller-relative path or a command on PATH and validate it."""
    argument = os.fspath(argument)
    if not argument:
        raise ArtifactError(f"{label} executable must not be empty")
    path = Path(argument).expanduser()
    if "/" in argument or "\\" in argument or path.is_file():
        path = path.resolve()
    else:
        found = shutil.which(argument)
        if found is None:
            raise ArtifactError(f"{label} executable not found on PATH: {argument}")
        path = Path(found).resolve()
    if not path.is_file() or not os.access(path, os.X_OK):
        raise ArtifactError(f"{label} executable is missing or not executable: {path}")
    return str(path)


def _run(command, label, **kwargs):
    try:
        return subprocess.run(command, check=True, **kwargs)
    except subprocess.CalledProcessError as error:
        raise ArtifactError(f"{label} exited with status {error.returncode}") from None
    except OSError as error:
        raise ArtifactError(f"could not run {label}: {error}") from None


def resolve_tool(root: Path, name: str, override=None) -> str:
    label = "PROMT" if name == "promt" else "ProSe"
    if override is not None:
        return _executable(override, label)
    installed = shutil.which(name)
    if installed:
        return _executable(installed, label)
    project = Path(root).resolve() / name
    if not project.is_dir():
        raise ArtifactError(f"missing {label} project directory: {project}")
    if name == "promt":
        print("Building PROMT (exe:promt)...", file=sys.stderr, flush=True)
        _run(["cabal", "build", "exe:promt"], "cabal build exe:promt",
             cwd=project, stdout=sys.stderr)
        result = _run(["cabal", "list-bin", "exe:promt"],
                      "cabal list-bin exe:promt", cwd=project,
                      stdout=subprocess.PIPE, text=True, encoding="utf-8")
        output = result.stdout.strip()
        if not output or len(output.splitlines()) != 1:
            raise ArtifactError("cabal list-bin exe:promt did not return one executable path")
        return _executable(project / output, label)
    command = ["dune", "build", "bin/main.exe"]
    if shutil.which("opam") is not None:
        command = ["opam", "exec", "--", *command]
    print(f"Building ProSe ({' '.join(command)})...", file=sys.stderr, flush=True)
    _run(command, " ".join(command), cwd=project, stdout=sys.stderr)
    return _executable(project / "_build/default/bin/main.exe", label)


def resolve_tools(root: Path, promt=None, prose=None) -> tuple[str, str]:
    # Check explicit paths before starting either build.
    promt = _executable(promt, "PROMT") if promt is not None else None
    prose = _executable(prose, "ProSe") if prose is not None else None
    return resolve_tool(root, "promt", promt), resolve_tool(root, "prose", prose)


def _source(path):
    path = Path(path).expanduser().resolve()
    if not path.is_file():
        raise ArtifactError(f"input file does not exist or is not a regular file: {path}")
    return path


def adapt_context(text: str) -> str:
    """Adapt exported weights for the original ProSe decimal-only lexer.

    Only probability tokens change. ProSe still uses floating-point values and
    its original six-significant-digit PRISM printer. Nat cannot be represented
    by its sort grammar and must not silently become Int.
    """
    masked = re.sub(r"\(\*.*?\*\)", lambda m: "".join(
        "\n" if c == "\n" else " " for c in m[0]), text, flags=re.S)
    if "(*" in masked:
        raise ArtifactError("unterminated context comment")
    if not masked.strip():
        raise ArtifactError("empty context")
    if re.search(r"<\s*Nat\s*>|\(\s*Nat\s*\)", masked):
        raise ArtifactError("PROMT exported a Nat payload sort, which original ProSe does not support")

    def probability(match):
        token = match[2]
        try:
            value = Fraction(token)
        except (ValueError, ZeroDivisionError):
            raise ArtifactError(f"invalid exported probability: {token}") from None
        if not 0 <= value <= 1:
            raise ArtifactError(f"exported probability is outside [0, 1]: {token}")
        if value and float(value) == 0:
            raise ArtifactError(f"exported probability underflows ProSe's float representation: {token}")
        if "/" in token:
            if not re.fullmatch(r"[0-9]+/[0-9]+", token):
                raise ArtifactError(f"invalid exported rational probability: {token}")
            token = format(Decimal(format(float(value), ".17g")), "f")
        elif not re.fullmatch(r"0|1|1\.0|0\.[0-9]*", token):
            raise ArtifactError(f"unsupported exported probability syntax: {token}")
        return token

    parts, end = [], 0
    for match in re.finditer(r"(!\s*)([^\s:]+)(\s*:)", masked):
        start, stop = match.span(2)
        parts.extend([text[end:start], probability(match)])
        end = stop
    return "".join([*parts, text[end:]])


def infer(source: Path, context: Path, promt: str) -> None:
    """Write an exact .ctx export atomically, preserving any output on failure."""
    source = _source(source)
    context = Path(context).expanduser().resolve()
    if source == context or (context.exists() and source.samefile(context)):
        raise ArtifactError("the input source and output context must be different files")
    binary = _executable(promt, "PROMT")
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=context.parent, prefix=".infer-", delete=False) as output:
            temporary = Path(output.name)
            _run([binary, "infer", "--", str(source)], "PROMT inference", stdout=output)
        if not temporary.read_text(encoding="utf-8").strip():
            raise ArtifactError("PROMT inference produced an empty context")
        temporary.replace(context)
    except OSError as error:
        raise ArtifactError(f"could not write inferred context {context}: {error}") from None
    except UnicodeError:
        raise ArtifactError("PROMT inference did not produce a UTF-8 context") from None
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def model_check(source: Path, prose: str, options=()):
    """Adapt only a temporary copy; the original exact context is never changed."""
    source = _source(source)
    text = adapt_context(source.read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory(prefix="promt-model-check-") as directory:
        context = Path(directory) / source.name
        context.write_text(text, encoding="utf-8")
        _run([prose, "verify", str(context), *options], "ProSe verification")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    def tools_options(target, suppressed=False):
        default = argparse.SUPPRESS if suppressed else None
        target.add_argument("--promt-bin", default=default, help="PROMT executable (skip build)")
        target.add_argument("--prose-bin", default=default, help="ProSe executable (skip build)")
    tools_options(parser)
    modes = parser.add_subparsers(dest="mode", required=True)
    for name, help_text in [
        ("infer", "infer an exact .ctx file from processes"),
        ("typecheck", "check processes against a separate .ctx specification"),
        ("subtype", "check each left participant against the corresponding right type"),
        ("model-check", "model-check a .ctx file with ProSe and PRISM"),
        ("verify", "infer processes and model-check the result")]:
        mode = modes.add_parser(name, help=help_text, description=help_text)
        tools_options(mode, suppressed=True)
        mode.add_argument("source", type=Path, help="left .ctx file" if name == "subtype" else "input file")
        if name in ("typecheck", "subtype"):
            mode.add_argument("specification", type=Path, help="specification/right .ctx file")
        if name == "infer":
            mode.add_argument("-o", "--output", type=Path, help="output .ctx file (default: stdout)")
    arguments = list(sys.argv[1:] if argv is None else argv)
    # Global executable flags take values; skip them to identify the subcommand.
    leading = iter(arguments)
    name = None
    for token in leading:
        if token in ("--promt-bin", "--prose-bin"):
            next(leading, None)
        elif not token.startswith("-"):
            name = token
            break
    options = []
    if name in ("verify", "model-check") and "--" in arguments:
        boundary = arguments.index("--")
        options, arguments = arguments[boundary + 1:], arguments[:boundary]
    args = parser.parse_args(arguments)
    root = Path(__file__).resolve().parent
    try:
        source = _source(args.source)
        if args.mode in ("typecheck", "subtype"):
            specification = _source(args.specification)
            promt = resolve_tool(root, "promt", args.promt_bin)
            _run([promt, args.mode, "--", str(source), str(specification)], "PROMT " + args.mode)
        elif args.mode == "infer":
            promt = resolve_tool(root, "promt", args.promt_bin)
            if args.output:
                infer(source, args.output, promt)
            else:
                _run([promt, "infer", "--", str(source)], "PROMT inference")
        elif args.mode == "model-check":
            prose = resolve_tool(root, "prose", args.prose_bin)
            model_check(source, prose, options)
        else:
            promt, prose = resolve_tools(root, args.promt_bin, args.prose_bin)
            with tempfile.TemporaryDirectory(prefix="promt-verify-") as directory:
                context = Path(directory) / (source.stem + ".ctx")
                infer(source, context, promt)
                model_check(context, prose, options)
    except (ArtifactError, OSError, UnicodeError) as error:
        print(f"Failed: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("Interrupted.", file=sys.stderr)
        return 130
    return 0


if __name__ == "__main__":
    sys.exit(main())
