#!/usr/bin/env python3

import argparse
import json
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path


DEFAULT_REPO = "osmandapp/OsmAnd-iOS"
DEFAULT_CACHE_DIR = Path.home() / ".cache" / "osmand-symbolication"

SCRIPT_DIR = Path(__file__).resolve().parent
SYMBOLICATE_SCRIPT = SCRIPT_DIR / "symbolicate_metrickit.py"


def log(message=""):
    print(message, flush=True)


def run(args, capture_output=False):
    log(f"$ {' '.join(str(arg) for arg in args)}")

    return subprocess.run(
        [str(arg) for arg in args],
        check=True,
        text=True,
        capture_output=capture_output,
    )


def check_dependencies():
    if shutil.which("gh") is None:
        raise RuntimeError(
            "GitHub CLI 'gh' is not installed.\n"
            "Install it with:\n"
            "  brew install gh\n\n"
            "Then authenticate:\n"
            "  gh auth login"
        )

    if not SYMBOLICATE_SCRIPT.exists():
        raise RuntimeError(
            f"Symbolication script not found:\n"
            f"  {SYMBOLICATE_SCRIPT}"
        )


def find_json_value(data, key):
    """
    Recursively find the first value for key in JSON.
    """
    if isinstance(data, dict):
        if key in data:
            return data[key]

        for value in data.values():
            result = find_json_value(value, key)
            if result is not None:
                return result

    elif isinstance(data, list):
        for item in data:
            result = find_json_value(item, key)
            if result is not None:
                return result

    return None


def load_crash_info(crash_path: Path):
    with crash_path.open("r", encoding="utf-8") as file:
        data = json.load(file)

    version = find_json_value(data, "appVersion")
    build = find_json_value(data, "appBuildVersion")

    if version is None:
        raise RuntimeError(
            f"'appVersion' not found anywhere in:\n"
            f"  {crash_path}"
        )

    if build is None:
        raise RuntimeError(
            f"'appBuildVersion' not found anywhere in:\n"
            f"  {crash_path}"
        )

    return str(version), str(build)


def parse_paginated_json(text: str):
    decoder = json.JSONDecoder()

    objects = []
    position = 0

    while position < len(text):
        while position < len(text) and text[position].isspace():
            position += 1

        if position >= len(text):
            break

        obj, position = decoder.raw_decode(text, position)
        objects.append(obj)

    return objects


def find_github_artifact(repo: str, version: str, build: str):
    log()
    log(
        f"Searching GitHub Actions artifact for "
        f"version {version}, build {build}..."
    )

    result = run(
        [
            "gh",
            "api",
            "--paginate",
            f"/repos/{repo}/actions/artifacts?per_page=100",
        ],
        capture_output=True,
    )

    pages = parse_paginated_json(result.stdout)

    artifacts = []

    for page in pages:
        artifacts.extend(page.get("artifacts", []))

    exact_marker = f"{version}.{build}"

    candidates = [
        artifact
        for artifact in artifacts
        if not artifact.get("expired", False)
        and exact_marker in artifact.get("name", "")
    ]

    if not candidates:
        build_markers = (
            f".{build}.",
            f"-{build}.",
            f".{build}-",
            f"-{build}-",
        )

        candidates = [
            artifact
            for artifact in artifacts
            if not artifact.get("expired", False)
            and any(
                marker in artifact.get("name", "")
                for marker in build_markers
            )
        ]

    if not candidates:
        raise RuntimeError(
            f"No non-expired GitHub Actions artifact found for:\n"
            f"  version: {version}\n"
            f"  build:   {build}"
        )

    candidates.sort(
        key=lambda artifact: artifact.get("created_at", ""),
        reverse=True,
    )

    artifact = candidates[0]

    log()
    log("Found artifact:")
    log(f"  Name:    {artifact['name']}")
    log(f"  ID:      {artifact['id']}")
    log(f"  Created: {artifact.get('created_at', 'unknown')}")

    return artifact


def download_artifact(repo: str, artifact: dict, destination: Path):
    if destination.exists() and destination.stat().st_size > 0:
        log()
        log("Using cached GitHub artifact:")
        log(f"  {destination}")
        return

    destination.parent.mkdir(parents=True, exist_ok=True)

    temporary = destination.with_suffix(destination.suffix + ".tmp")

    if temporary.exists():
        temporary.unlink()

    log()
    log("Downloading artifact...")
    log(f"  {artifact['name']}")

    try:
        with temporary.open("wb") as output:
            subprocess.run(
                [
                    "gh",
                    "api",
                    f"/repos/{repo}/actions/artifacts/{artifact['id']}/zip",
                ],
                check=True,
                stdout=output,
            )

        temporary.rename(destination)

    except Exception:
        if temporary.exists():
            temporary.unlink()
        raise

    log()
    log("Downloaded:")
    log(f"  {destination}")


def find_xcarchive(directory: Path):
    if not directory.exists():
        return None

    archives = list(directory.rglob("*.xcarchive"))

    if not archives:
        return None

    if len(archives) > 1:
        log()
        log("Warning: multiple .xcarchive files found:")

        for archive in archives:
            log(f"  {archive}")

        log()
        log("Using:")
        log(f"  {archives[0]}")

    return archives[0]


def extract_zip(zip_path: Path, destination: Path):
    destination.mkdir(parents=True, exist_ok=True)

    log()
    log("Extracting:")
    log(f"  {zip_path}")

    with zipfile.ZipFile(zip_path, "r") as archive:
        archive.extractall(destination)


def extract_xcarchive(download_path: Path, extract_dir: Path):
    existing_archive = find_xcarchive(extract_dir)

    if existing_archive:
        log()
        log("Using cached xcarchive:")
        log(f"  {existing_archive}")
        return existing_archive

    if extract_dir.exists():
        shutil.rmtree(extract_dir)

    extract_dir.mkdir(parents=True, exist_ok=True)

    extract_zip(download_path, extract_dir)

    archive = find_xcarchive(extract_dir)

    if archive:
        return archive

    nested_zips = list(extract_dir.rglob("*.zip"))

    for nested_zip in nested_zips:
        nested_dir = (
            nested_zip.parent
            / f"{nested_zip.stem}_extracted"
        )

        if not nested_dir.exists():
            extract_zip(
                nested_zip,
                nested_dir,
            )

        archive = find_xcarchive(nested_dir)

        if archive:
            return archive

    raise RuntimeError(
        f"No .xcarchive found after extracting:\n"
        f"  {download_path}"
    )


def get_archive(
    repo: str,
    version: str,
    build: str,
    cache_dir: Path,
):
    build_dir = cache_dir / f"{version}-{build}"
    extract_dir = build_dir / "extracted"

    archive = find_xcarchive(extract_dir)

    if archive:
        log()
        log("Archive already exists locally.")
        log("Download is not required.")
        log(f"  {archive}")

        return archive

    if build_dir.exists():
        downloaded_zips = list(
            build_dir.glob("github-artifact-*.zip")
        )

        if downloaded_zips:
            downloaded_zips.sort(
                key=lambda path: path.stat().st_mtime,
                reverse=True,
            )

            download_path = downloaded_zips[0]

            log()
            log("GitHub artifact is already downloaded.")
            log(f"  {download_path}")

            return extract_xcarchive(
                download_path,
                extract_dir,
            )

    artifact = find_github_artifact(
        repo,
        version,
        build,
    )

    download_path = (
        build_dir
        / f"github-artifact-{artifact['id']}.zip"
    )

    download_artifact(
        repo,
        artifact,
        download_path,
    )

    return extract_xcarchive(
        download_path,
        extract_dir,
    )


def symbolicate(
    crash_path: Path,
    archive_path: Path,
    output_path: Path,
):
    log()
    log("=" * 70)
    log("Symbolicating crash")
    log("=" * 70)

    run(
        [
            sys.executable,
            SYMBOLICATE_SCRIPT,
            crash_path,
            "--archives",
            archive_path,
            "--no-spotlight",
            "--output",
            output_path,
        ]
    )


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Automatically find/download matching "
            "OsmAnd xcarchive and symbolicate "
            "a MetricKit crash."
        )
    )

    parser.add_argument(
        "crash",
        type=Path,
        help="Path to MetricKit crash JSON",
    )

    parser.add_argument(
        "--repo",
        default=DEFAULT_REPO,
        help=f"GitHub repository (default: {DEFAULT_REPO})",
    )

    parser.add_argument(
        "--cache-dir",
        type=Path,
        default=DEFAULT_CACHE_DIR,
        help=(
            "Archive cache directory "
            f"(default: {DEFAULT_CACHE_DIR})"
        ),
    )

    parser.add_argument(
        "--output",
        type=Path,
        help="Output symbolicated TXT file",
    )

    args = parser.parse_args()

    check_dependencies()

    crash_path = args.crash.expanduser().resolve()

    if not crash_path.exists():
        raise RuntimeError(
            f"Crash file does not exist:\n"
            f"  {crash_path}"
        )

    cache_dir = args.cache_dir.expanduser().resolve()

    version, build = load_crash_info(crash_path)

    log()
    log("=" * 70)
    log("OsmAnd MetricKit Symbolication")
    log("=" * 70)

    log("Crash:")
    log(f"  {crash_path}")

    log("Version:")
    log(f"  {version}")

    log("Build:")
    log(f"  {build}")

    archive_path = get_archive(
        args.repo,
        version,
        build,
        cache_dir,
    )

    if args.output:
        output_path = (
            args.output
            .expanduser()
            .resolve()
        )
    else:
        output_path = crash_path.with_name(
            f"{crash_path.stem}-symbolicated.txt"
        )

    symbolicate(
        crash_path,
        archive_path,
        output_path,
    )

    log()
    log("=" * 70)
    log("Done")
    log("=" * 70)

    log("Archive:")
    log(f"  {archive_path}")

    log()
    log("Symbolicated crash:")
    log(f"  {output_path}")


if __name__ == "__main__":
    try:
        main()

    except subprocess.CalledProcessError as error:
        log()

        print(
            f"Command failed with exit code {error.returncode}",
            file=sys.stderr,
        )

        sys.exit(error.returncode)

    except KeyboardInterrupt:
        log()

        print(
            "Cancelled.",
            file=sys.stderr,
        )

        sys.exit(130)

    except Exception as error:
        log()

        print(
            f"Error: {error}",
            file=sys.stderr,
        )

        sys.exit(1)