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
import textwrap
from dataclasses import dataclass
from typing import Any, Iterable, Iterator, Sequence


UUID_PATTERN = re.compile(
    r"UUID:\s+([0-9A-Fa-f-]{36})\s+\(([^)]+)\)\s+(.+)$"
)
DEFAULT_ARCHIVES = Path.home() / "Library" / "Developer" / "Xcode" / "Archives"
DETAIL_LABELS = {
    "version": "Report format version",
    "applicationVersion": "Application version",
    "terminationReason": "Termination reason",
    "exceptionType": "Exception type",
    "exceptionCode": "Exception code",
    "virtualMemoryRegionInfo": "Virtual memory region",
}
EXCEPTION_TYPES = {
    1: "EXC_BAD_ACCESS",
    2: "EXC_BAD_INSTRUCTION",
    3: "EXC_ARITHMETIC",
    4: "EXC_EMULATION",
    5: "EXC_SOFTWARE",
    6: "EXC_BREAKPOINT",
    7: "EXC_SYSCALL",
    8: "EXC_MACH_SYSCALL",
    9: "EXC_RPC_ALERT",
    10: "EXC_CRASH",
    11: "EXC_RESOURCE",
    12: "EXC_GUARD",
    13: "EXC_CORPSE_NOTIFY",
}
SIGNALS = {
    4: "SIGILL",
    5: "SIGTRAP",
    6: "SIGABRT",
    7: "SIGBUS",
    8: "SIGFPE",
    9: "SIGKILL",
    11: "SIGSEGV",
    13: "SIGPIPE",
    15: "SIGTERM",
}


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
    metadata: dict[str, Any]
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
    metadata = value.get("diagnosticMetaData")
    if not isinstance(metadata, dict):
        metadata = {}
    return Diagnostic(source, ordinal, details, metadata, threads)


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


def human_value(value: Any) -> str:
    if isinstance(value, bool):
        return "yes" if value else "no"
    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return str(value)


def metadata_value(key: str, value: Any) -> Any:
    if isinstance(value, int) and not isinstance(value, bool):
        if key == "exceptionType" and value in EXCEPTION_TYPES:
            return f"{EXCEPTION_TYPES[value]} ({value})"
        if key == "signal" and value in SIGNALS:
            return f"{SIGNALS[value]} ({value})"
    return value


def first_match(pattern: str, value: str) -> str | None:
    match = re.search(pattern, value, re.MULTILINE | re.DOTALL)
    return match.group(1).strip() if match else None


def parse_termination_reason(value: Any) -> dict[str, str]:
    if not isinstance(value, str) or not value:
        return {}

    details: dict[str, str] = {}
    code = first_match(r"\bcode:(0x[0-9A-Fa-f]+)", value)
    watchdog_event = first_match(r"^WatchdogEvent:\s*([^\n]+)", value)
    timeout = first_match(r"time allowance of ([0-9.]+ seconds)", value)

    if code == "0x8BADF00D" or watchdog_event:
        details["Type"] = "Watchdog termination"
    if code:
        details["Code"] = code
    if watchdog_event:
        details["Event"] = watchdog_event
    if timeout:
        details["Time limit"] = timeout

    fields = (
        ("Process visibility", r"^ProcessVisibility:\s*([^\n]+)"),
        ("Process state", r"^ProcessState:\s*([^\n]+)"),
        ("Thermal level", r'"Thermal Level:\s*([^"\n]+)'),
        ("Thermal state", r'"Thermal State:\s*([^"\n]+)'),
        ("Report type", r"\breportType:([^\s>]+)"),
        (
            "Termination resistance",
            r"\bmaxTerminationResistance:([^\s>]+)",
        ),
    )
    for label, pattern in fields:
        match = first_match(pattern, value)
        if match:
            details[label] = match

    total_cpu = re.search(
        r"Elapsed total CPU time \(seconds\):\s*([0-9.]+) "
        r"\(user ([0-9.]+), system ([0-9.]+)\),\s*([0-9]+% CPU)",
        value,
    )
    if total_cpu:
        total, user, system, percentage = total_cpu.groups()
        details["Total CPU"] = (
            f"{total} s ({percentage}; user {user} s, system {system} s)"
        )

    application_cpu = re.search(
        r"Elapsed application CPU time \(seconds\):\s*([0-9.]+),\s*"
        r"([0-9]+% CPU)",
        value,
    )
    if application_cpu:
        elapsed, percentage = application_cpu.groups()
        details["Application CPU"] = f"{elapsed} s ({percentage})"

    explanation = first_match(
        r"\bexplanation:(.*?)(?=\n[A-Z][A-Za-z]+:|\nThermalInfo:|"
        r"\sreportType:|\smaxTerminationResistance:|>$)",
        value,
    )
    if explanation:
        details["Explanation"] = " ".join(explanation.split())

    return details


def append_labeled_value(
    output: list[str],
    indentation: str,
    label: str,
    value: Any,
) -> None:
    prefix_width = len(indentation) + len(label) + 2
    lines = []
    for source_line in human_value(value).splitlines() or [""]:
        lines.extend(
            textwrap.wrap(
                source_line,
                width=max(40, 120 - prefix_width),
                break_long_words=False,
                break_on_hyphens=False,
            )
            or [""]
        )
    output.append(f"{indentation}{label}: {lines[0]}")
    continuation = f"{indentation}{' ' * (len(label) + 2)}"
    output.extend(f"{continuation}{line}" for line in lines[1:])


def clean_symbol_name(value: str) -> str:
    return value.split(" (in ", 1)[0].strip()


def is_relevant_app_symbol(value: str) -> bool:
    name = clean_symbol_name(value)
    if name.startswith("objc2kotlin_"):
        return False
    return (
        name.startswith(("-[", "+["))
        or "net.osmand" in name
        or "OsmAnd::" in name
    )


def render_incident_summary(
    diagnostic: Diagnostic,
    symbolicated: dict[tuple[str, int], str],
) -> list[str]:
    termination = parse_termination_reason(
        diagnostic.metadata.get("terminationReason")
    )
    attributed_thread = next(
        (
            (index, thread)
            for index, thread in enumerate(diagnostic.threads)
            if thread.attributed
        ),
        None,
    )

    exception_type = diagnostic.metadata.get("exceptionType")
    signal = diagnostic.metadata.get("signal")
    incident_type = termination.get("Type")
    if not incident_type and exception_type is not None:
        incident_type = str(metadata_value("exceptionType", exception_type))
    if not incident_type:
        incident_type = "Crash"
    output = ["Incident summary:", f"  Type: {incident_type}"]
    if signal is not None:
        output.append(f"  Signal: {metadata_value('signal', signal)}")
    memory_region = diagnostic.metadata.get("virtualMemoryRegionInfo")
    if isinstance(memory_region, str):
        fault_address = first_match(r"^\s*(0x[0-9A-Fa-f]+)\b", memory_region)
        if fault_address:
            output.append(f"  Fault address: {fault_address}")
    if termination.get("Event"):
        output.append(f"  Watchdog event: {termination['Event']}")
    if termination.get("Time limit"):
        output.append(f"  Time limit: {termination['Time limit']}")
    if termination.get("Process state") or termination.get("Process visibility"):
        process = " / ".join(
            value
            for value in (
                termination.get("Process state"),
                termination.get("Process visibility"),
            )
            if value
        )
        output.append(f"  Process: {process}")

    if attributed_thread:
        thread_index, thread = attributed_thread
        output.append(f"  Attributed thread: {thread_index}")
        relevant_path: list[str] = []
        top_description: str | None = None
        if thread.frames:
            top_frame = thread.frames[0]
            top_name = resolved_frame_name(top_frame, symbolicated)
            if top_name:
                top_description = clean_symbol_name(top_name)
            else:
                location = frame_location(top_frame)
                top_description = top_frame.binary_name
                if location:
                    top_description += f" ({location})"
            append_labeled_value(output, "  ", "Top frame", top_description)

        top_application_frame: str | None = None
        for frame in thread.frames:
            key = (
                (frame.binary_uuid, frame.offset)
                if frame.binary_uuid and frame.offset is not None
                else None
            )
            name = symbolicated.get(key) if key else None
            if name:
                if top_application_frame is None:
                    top_application_frame = clean_symbol_name(name)
                if is_relevant_app_symbol(name):
                    relevant_path.append(clean_symbol_name(name))
        if top_application_frame and top_application_frame != top_description:
            append_labeled_value(
                output,
                "  ",
                "Top application frame",
                top_application_frame,
            )
        if relevant_path:
            output.append("  Relevant app path:")
            output.extend(
                f"    {index}. {name}"
                for index, name in enumerate(relevant_path[:6], start=1)
            )
    return output


def render_metadata(metadata: dict[str, Any]) -> list[str]:
    """Render MetricKit metadata in stable, readable groups without losing fields."""
    if not metadata:
        return []

    output = ["Diagnostic metadata:"]
    rendered_keys: set[str] = set()

    version = metadata.get("appVersion")
    build = metadata.get("appBuildVersion")
    application: list[tuple[str, Any]] = []
    if version is not None and build is not None:
        application.append(("Version", f"{version} (build {build})"))
        rendered_keys.update(("appVersion", "appBuildVersion"))
    else:
        if version is not None:
            application.append(("Version", version))
            rendered_keys.add("appVersion")
        if build is not None:
            application.append(("Build", build))
            rendered_keys.add("appBuildVersion")

    groups = (
        (
            "Application",
            application,
            (
                ("Bundle identifier", "bundleIdentifier"),
                ("TestFlight", "isTestFlightApp"),
            ),
        ),
        (
            "Device and OS",
            [],
            (
                ("OS", "osVersion"),
                ("Device", "deviceType"),
                ("Architecture", "platformArchitecture"),
                ("Region", "regionFormat"),
            ),
        ),
        (
            "Exception",
            [],
            (
                ("Type", "exceptionType"),
                ("Code", "exceptionCode"),
                ("Signal", "signal"),
            ),
        ),
        (
            "Process and power",
            [],
            (
                ("PID", "pid"),
                ("Low Power Mode", "lowPowerModeEnabled"),
            ),
        ),
    )

    for heading, initial_values, fields in groups:
        values = list(initial_values)
        for label, key in fields:
            if key in metadata and metadata[key] is not None:
                values.append((label, metadata_value(key, metadata[key])))
                rendered_keys.add(key)
        if values:
            output.append(f"  {heading}:")
            for label, value in values:
                append_labeled_value(output, "    ", label, value)

    termination_reason = metadata.get("terminationReason")
    termination = parse_termination_reason(termination_reason)
    if termination:
        rendered_keys.add("terminationReason")
        output.append("  Termination:")
        for label, value in termination.items():
            append_labeled_value(output, "    ", label, value)

    additional = [
        (key, value)
        for key, value in metadata.items()
        if key not in rendered_keys and value is not None
    ]
    if additional:
        output.append("  Additional metadata:")
        for key, value in additional:
            append_labeled_value(output, "    ", key, value)
    return output


def resolved_frame_name(
    frame: Frame,
    symbolicated: dict[tuple[str, int], str],
) -> str | None:
    if frame.binary_uuid and frame.offset is not None:
        return symbolicated.get((frame.binary_uuid, frame.offset))
    return None


def render_thread_frames(
    output: list[str],
    thread: Thread,
    symbolicated: dict[tuple[str, int], str],
    symbols: dict[str, SymbolFile],
) -> None:
    for frame in thread.frames:
        name = resolved_frame_name(frame, symbolicated)
        location = frame_location(frame)
        if name:
            output.append(f"{frame.index:>4}  {frame.binary_name}  {name}")
        else:
            reason = ""
            if frame.binary_uuid and frame.binary_uuid not in symbols:
                reason = " [no matching dSYM]"
            output.append(
                f"{frame.index:>4}  {frame.binary_name}  {location}{reason}"
            )


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
            output.append(f"{DETAIL_LABELS.get(key, key)}: {value}")
        output.append("")
        output.extend(render_incident_summary(diagnostic, symbolicated))
        if diagnostic.metadata:
            output.append("")
            output.extend(render_metadata(diagnostic.metadata))

        if not diagnostic.threads:
            output.append("No call-stack threads found")
            continue

        for thread_index, thread in enumerate(diagnostic.threads):
            output.append("")
            suffix = " [attributed]" if thread.attributed else ""
            output.append(f"Thread {thread_index}{suffix}")
            if not thread.frames:
                output.append("  No frames")
                continue
            render_thread_frames(
                output,
                thread,
                symbolicated,
                symbols,
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
