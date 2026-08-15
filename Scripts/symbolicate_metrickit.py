#!/usr/bin/env python3
"""Symbolicate every thread in MetricKit diagnostic JSON reports.

The script resolves dSYMs by binary UUID, batches all offsets for each binary
through atos, and then prints the original recursive MetricKit call-stack tree.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from dataclasses import dataclass
from typing import Any, Iterable, Iterator, Sequence


UUID_PATTERN = re.compile(
    r"UUID:\s+([0-9A-Fa-f-]{36})\s+\(([^)]+)\)\s+(.+)$"
)
DEFAULT_ARCHIVES = Path.home() / "Library" / "Developer" / "Xcode" / "Archives"


@dataclass(frozen=True)
class SymbolFile:
    uuid: str
    architecture: str
    dwarf_path: Path


@dataclass
class Frame:
    binary_name: str
    binary_uuid: str | None
    offset: int | None
    address: int | None
    depth: int
    index: int


@dataclass
class Thread:
    attributed: bool
    frames: list[Frame]


@dataclass
class Diagnostic:
    source: Path
    ordinal: int
    details: dict[str, Any]
    threads: list[Thread]


def run(command: Sequence[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )


def normalize_uuid(value: Any) -> str | None:
    if not isinstance(value, str):
        return None
    normalized = value.strip().upper()
    return normalized if normalized else None


def integer(value: Any) -> int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        try:
            return int(value, 0)
        except ValueError:
            return None
    return None


def find_diagnostics(value: Any) -> Iterator[dict[str, Any]]:
    """Find diagnostics without depending on a particular payload wrapper."""
    if isinstance(value, dict):
        if isinstance(value.get("callStackTree"), dict):
            yield value
            return
        for child in value.values():
            yield from find_diagnostics(child)
    elif isinstance(value, list):
        for child in value:
            yield from find_diagnostics(child)


def unwrap_tree(value: dict[str, Any]) -> dict[str, Any]:
    tree = value
    while (
        isinstance(tree.get("callStackTree"), dict)
        and "callStacks" not in tree
        and "callStackThreads" not in tree
    ):
        tree = tree["callStackTree"]
    return tree


def binary_names(tree: dict[str, Any]) -> dict[str, str]:
    result: dict[str, str] = {}
    info = tree.get("binaryInfo")
    if not isinstance(info, dict):
        return result

    for uuid, metadata in info.items():
        if not isinstance(metadata, dict):
            continue
        name = metadata.get("binaryName") or metadata.get("name")
        normalized_uuid = normalize_uuid(uuid)
        if normalized_uuid and isinstance(name, str):
            result[normalized_uuid] = name
    return result


def flatten_frames(
    roots: Any,
    known_binary_names: dict[str, str],
) -> list[Frame]:
    frames: list[Frame] = []

    def visit(value: Any, depth: int) -> None:
        if not isinstance(value, dict):
            return
        binary_uuid = normalize_uuid(value.get("binaryUUID"))
        name = value.get("binaryName")
        if not isinstance(name, str):
            name = known_binary_names.get(binary_uuid or "", "<unknown>")
        frames.append(
            Frame(
                binary_name=name,
                binary_uuid=binary_uuid,
                offset=integer(value.get("offsetIntoBinaryTextSegment")),
                address=integer(value.get("address")),
                depth=depth,
                index=len(frames),
            )
        )
        children = value.get("subFrames")
        if not isinstance(children, list):
            children = []
        for child in children:
            visit(child, depth + 1)

    if isinstance(roots, list):
        for root in roots:
            visit(root, 0)
    return frames


def parse_diagnostic(source: Path, ordinal: int, value: dict[str, Any]) -> Diagnostic:
    tree = unwrap_tree(value["callStackTree"])
    names = binary_names(tree)
    raw_threads = tree.get("callStacks")
    if not isinstance(raw_threads, list):
        raw_threads = tree.get("callStackThreads")
    if not isinstance(raw_threads, list):
        raw_threads = []

    threads: list[Thread] = []
    for raw_thread in raw_threads:
        if not isinstance(raw_thread, dict):
            continue
        roots = raw_thread.get("callStackRootFrames")
        if not isinstance(roots, list):
            roots = raw_thread.get("rootFrames")
        attributed = bool(raw_thread.get("threadAttributed", False))
        threads.append(Thread(attributed, flatten_frames(roots, names)))

    details = {
        key: value[key]
        for key in (
            "version",
            "applicationVersion",
            "terminationReason",
            "exceptionType",
            "exceptionCode",
            "signal",
            "virtualMemoryRegionInfo",
        )
        if key in value and value[key] is not None
    }
    return Diagnostic(source, ordinal, details, threads)


def load_reports(paths: Iterable[Path]) -> list[Diagnostic]:
    diagnostics: list[Diagnostic] = []
    for path in paths:
        try:
            with path.open("r", encoding="utf-8") as report_file:
                payload = json.load(report_file)
        except (OSError, json.JSONDecodeError) as error:
            raise RuntimeError(f"Cannot read {path}: {error}") from error

        for ordinal, value in enumerate(find_diagnostics(payload), start=1):
            diagnostics.append(parse_diagnostic(path, ordinal, value))
    return diagnostics


def dwarf_files_in_dsym(path: Path) -> Iterator[Path]:
    if path.is_file():
        yield path
        return
    dwarf_directory = path / "Contents" / "Resources" / "DWARF"
    if not dwarf_directory.is_dir():
        return
    for child in sorted(dwarf_directory.iterdir()):
        if child.is_file():
            yield child


def inspect_dwarf(path: Path) -> list[SymbolFile]:
    result = run(["xcrun", "dwarfdump", "--uuid", str(path)])
    symbols: list[SymbolFile] = []
    for line in result.stdout.splitlines():
        match = UUID_PATTERN.search(line)
        if match:
            symbols.append(
                SymbolFile(match.group(1).upper(), match.group(2), path)
            )
    return symbols


def spotlight_candidates(uuid: str) -> Iterator[Path]:
    result = run(["mdfind", f"com_apple_xcode_dsym_uuids == {uuid}"])
    if result.returncode != 0:
        return
    for line in result.stdout.splitlines():
        candidate = Path(line.strip())
        if candidate.exists():
            yield candidate


def archive_dsym_bundles(roots: Iterable[Path]) -> Iterator[Path]:
    for root in roots:
        if root.suffix == ".dSYM" and root.is_dir():
            yield root
            continue
        if root.suffix == ".xcarchive" and root.is_dir():
            dsym_root = root / "dSYMs"
            if dsym_root.is_dir():
                yield from sorted(dsym_root.glob("*.dSYM"))
            continue
        if not root.is_dir():
            continue
        for current, directories, _ in os.walk(root):
            current_path = Path(current)
            dsym_directories = [name for name in directories if name.endswith(".dSYM")]
            for name in sorted(dsym_directories):
                yield current_path / name
            directories[:] = [
                name
                for name in directories
                if not name.endswith(".dSYM") and name != "BCSymbolMaps"
            ]


def resolve_symbols(
    required_uuids: set[str],
    binary_names_by_uuid: dict[str, set[str]],
    archive_roots: Sequence[Path],
    use_spotlight: bool,
) -> dict[str, SymbolFile]:
    resolved: dict[str, SymbolFile] = {}
    inspected: set[Path] = set()

    if use_spotlight:
        for uuid in sorted(required_uuids):
            for candidate in spotlight_candidates(uuid):
                for dwarf in dwarf_files_in_dsym(candidate):
                    canonical = dwarf.resolve()
                    if canonical in inspected:
                        continue
                    inspected.add(canonical)
                    for symbol in inspect_dwarf(dwarf):
                        if symbol.uuid in required_uuids:
                            resolved.setdefault(symbol.uuid, symbol)
                if uuid in resolved:
                    break

    unresolved = required_uuids - resolved.keys()
    if unresolved:
        for dsym in archive_dsym_bundles(archive_roots):
            for dwarf in dwarf_files_in_dsym(dsym):
                unresolved_names = {
                    name
                    for uuid in unresolved
                    for name in binary_names_by_uuid.get(uuid, set())
                    if name != "<unknown>"
                }
                if unresolved_names and dwarf.name not in unresolved_names:
                    continue
                canonical = dwarf.resolve()
                if canonical in inspected:
                    continue
                inspected.add(canonical)
                for symbol in inspect_dwarf(dwarf):
                    if symbol.uuid in unresolved:
                        resolved[symbol.uuid] = symbol
            unresolved = required_uuids - resolved.keys()
            if not unresolved:
                break

    return resolved


def chunks(values: Sequence[int], size: int) -> Iterator[Sequence[int]]:
    for start in range(0, len(values), size):
        yield values[start : start + size]


def symbolicate(
    diagnostics: Sequence[Diagnostic],
    symbols: dict[str, SymbolFile],
) -> dict[tuple[str, int], str]:
    offsets_by_uuid: dict[str, set[int]] = {}
    for diagnostic in diagnostics:
        for thread in diagnostic.threads:
            for frame in thread.frames:
                if frame.binary_uuid and frame.offset is not None:
                    offsets_by_uuid.setdefault(frame.binary_uuid, set()).add(frame.offset)

    resolved_frames: dict[tuple[str, int], str] = {}
    for uuid, offsets_set in offsets_by_uuid.items():
        symbol_file = symbols.get(uuid)
        if not symbol_file:
            continue
        offsets = sorted(offsets_set)
        for batch in chunks(offsets, 500):
            command = [
                "xcrun",
                "atos",
                "-arch",
                symbol_file.architecture,
                "-o",
                str(symbol_file.dwarf_path),
                "-offset",
                *(hex(offset) for offset in batch),
            ]
            result = run(command)
            lines = result.stdout.splitlines()
            if result.returncode != 0 or len(lines) != len(batch):
                print(
                    f"warning: atos failed for {symbol_file.dwarf_path}: "
                    f"{result.stderr.strip() or 'unexpected output'}",
                    file=sys.stderr,
                )
                continue
            for offset, line in zip(batch, lines):
                resolved_frames[(uuid, offset)] = line.strip()
    return resolved_frames


def frame_location(frame: Frame) -> str:
    values: list[str] = []
    if frame.offset is not None:
        values.append(f"offset={hex(frame.offset)}")
    if frame.address is not None:
        values.append(f"address={hex(frame.address)}")
    if frame.binary_uuid:
        values.append(f"uuid={frame.binary_uuid}")
    return " ".join(values)


def render(
    diagnostics: Sequence[Diagnostic],
    symbolicated: dict[tuple[str, int], str],
    symbols: dict[str, SymbolFile],
) -> str:
    output: list[str] = []
    for diagnostic_index, diagnostic in enumerate(diagnostics):
        if diagnostic_index:
            output.append("")
        output.append(f"Report: {diagnostic.source}")
        output.append(f"Diagnostic: {diagnostic.ordinal}")
        for key, value in diagnostic.details.items():
            if isinstance(value, (dict, list)):
                value = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
            output.append(f"{key}: {value}")

        if not diagnostic.threads:
            output.append("No call-stack threads found")
            continue

        for thread_index, thread in enumerate(diagnostic.threads):
            output.append("")
            suffix = " [attributed/crashed]" if thread.attributed else ""
            output.append(f"Thread {thread_index}{suffix}")
            for frame in thread.frames:
                key = (
                    (frame.binary_uuid, frame.offset)
                    if frame.binary_uuid and frame.offset is not None
                    else None
                )
                name = symbolicated.get(key) if key else None
                indentation = "  " * frame.depth
                location = frame_location(frame)
                if name:
                    output.append(
                        f"{indentation}{frame.index:>4}  {frame.binary_name}  {name}"
                    )
                else:
                    reason = ""
                    if frame.binary_uuid and frame.binary_uuid not in symbols:
                        reason = " [no matching dSYM]"
                    output.append(
                        f"{indentation}{frame.index:>4}  {frame.binary_name}  "
                        f"{location}{reason}"
                    )
    return "\n".join(output) + "\n"


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Symbolicate all threads in MetricKit diagnostic JSON files."
    )
    parser.add_argument("reports", nargs="+", type=Path, help="MetricKit JSON file(s)")
    parser.add_argument(
        "--archives",
        action="append",
        type=Path,
        default=[],
        metavar="PATH",
        help=(
            "xcarchive, dSYM, or directory to scan when Spotlight cannot "
            "resolve a UUID; may be repeated"
        ),
    )
    parser.add_argument("-o", "--output", type=Path, help="write output to this file")
    parser.add_argument(
        "--no-spotlight",
        action="store_true",
        help=(
            "skip the fast mdfind lookup and scan --archives directly "
            f"(default scan path: {DEFAULT_ARCHIVES})"
        ),
    )
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    archive_roots = arguments.archives
    if arguments.no_spotlight and not archive_roots:
        archive_roots = [DEFAULT_ARCHIVES]

    try:
        diagnostics = load_reports(arguments.reports)
    except RuntimeError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    if not diagnostics:
        print("error: no MetricKit callStackTree values found", file=sys.stderr)
        return 2

    required_uuids = {
        frame.binary_uuid
        for diagnostic in diagnostics
        for thread in diagnostic.threads
        for frame in thread.frames
        if frame.binary_uuid and frame.offset is not None
    }
    binary_names_by_uuid: dict[str, set[str]] = {}
    for diagnostic in diagnostics:
        for thread in diagnostic.threads:
            for frame in thread.frames:
                if frame.binary_uuid:
                    binary_names_by_uuid.setdefault(frame.binary_uuid, set()).add(
                        frame.binary_name
                    )
    symbols = resolve_symbols(
        required_uuids,
        binary_names_by_uuid,
        archive_roots,
        use_spotlight=not arguments.no_spotlight,
    )
    symbolicated = symbolicate(diagnostics, symbols)
    rendered = render(diagnostics, symbolicated, symbols)

    if arguments.output:
        try:
            arguments.output.write_text(rendered, encoding="utf-8")
        except OSError as error:
            print(f"error: cannot write {arguments.output}: {error}", file=sys.stderr)
            return 2
    else:
        sys.stdout.write(rendered)

    resolved_count = len(symbols)
    print(
        f"Resolved dSYMs for {resolved_count}/{len(required_uuids)} binary UUIDs.",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
