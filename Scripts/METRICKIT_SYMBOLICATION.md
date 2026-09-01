# MetricKit crash report symbolication

This document describes how to symbolicate every thread in an OsmAnd MetricKit
crash report using [`symbolicate_metrickit.py`](symbolicate_metrickit.py). For a
debug build whose symbols are available only in `OsmAnd Maps.debug.dylib`, use
[`build_debug_dsym.sh`](build_debug_dsym.sh) first.

## Requirements

- macOS with Xcode and its command-line tools selected.
- An `osmand-crash-*.json` MetricKit report.
- Symbols from the exact build that produced the report:
  - the matching `.xcarchive` or `.dSYM`; or
  - the matching `OsmAnd Maps.debug.dylib` for a local debug build.

The app version is not enough to identify matching symbols. The binary UUID in
the report must match the UUID in the dSYM. Rebuilding the same source normally
produces a different UUID.

Crash reports copied from a device are available in:

`Files > On My iPhone > OsmAnd Maps > Logs`

Run the commands below from the root of the OsmAnd iOS repository.

## Symbolicate with an Xcode archive

Passing the exact archive directly is the fastest deterministic workflow:

```sh
python3 Scripts/symbolicate_metrickit.py \
  "/path/to/osmand-crash.json" \
  --archives "/path/to/OsmAnd Maps.xcarchive" \
  --no-spotlight \
  --output "/path/to/osmand-crash-symbolicated.txt"
```

`--archives` accepts an `.xcarchive`, a `.dSYM`, or a directory containing
archives or dSYMs. Repeat the option to search more than one location:

```sh
python3 Scripts/symbolicate_metrickit.py \
  "/path/to/osmand-crash.json" \
  --archives "/path/to/first/archive-or-dsym" \
  --archives "/path/to/second/archive-or-dsym" \
  --no-spotlight \
  --output "/path/to/osmand-crash-symbolicated.txt"
```

To let macOS Spotlight find dSYMs by UUID, omit both `--archives` and
`--no-spotlight`:

```sh
python3 Scripts/symbolicate_metrickit.py "/path/to/osmand-crash.json"
```

To scan the standard Xcode Archives directory without Spotlight, use
`--no-spotlight` without `--archives`:

```sh
python3 Scripts/symbolicate_metrickit.py \
  "/path/to/osmand-crash.json" \
  --no-spotlight \
  --output "/path/to/osmand-crash-symbolicated.txt"
```

That scans `~/Library/Developer/Xcode/Archives`.

## Symbolicate a local debug build

Modern Xcode debug builds can place the app's executable code in
`OsmAnd Maps.debug.dylib`. Create a dSYM from the exact dylib that produced the
crash:

1. In Xcode's Project navigator, expand **Products**.
2. Right-click `OsmAnd Maps.app` and select **Show in Finder**.
3. Right-click the app and select **Show Package Contents**.
4. Copy `OsmAnd Maps.debug.dylib` to a stable location before rebuilding.
5. Run:

```sh
Scripts/build_debug_dsym.sh "/path/to/OsmAnd Maps.debug.dylib"
```

The default output is placed beside the input binary as
`OsmAnd Maps.debug.dylib.dSYM`. To choose another output path, pass it as the
second argument:

```sh
Scripts/build_debug_dsym.sh \
  "/path/to/OsmAnd Maps.debug.dylib" \
  "/path/to/OsmAnd Maps.debug.dylib.dSYM"
```

The script refuses to overwrite an existing output and verifies that the
generated dSYM UUIDs match the input dylib UUIDs. After it succeeds, run:

```sh
python3 Scripts/symbolicate_metrickit.py \
  "/path/to/osmand-crash.json" \
  --archives "/path/to/OsmAnd Maps.debug.dylib.dSYM" \
  --no-spotlight \
  --output "/path/to/osmand-crash-symbolicated.txt"
```

Keep the copied dylib and generated dSYM together with the report. A dylib from
a later rebuild will not symbolicate the earlier report.

## Symbolicate several reports at once

Pass any number of JSON reports before the options:

```sh
python3 Scripts/symbolicate_metrickit.py \
  "/path/to/first-crash.json" \
  "/path/to/second-crash.json" \
  --archives "/path/to/OsmAnd Maps.xcarchive" \
  --no-spotlight \
  --output "/path/to/all-crashes-symbolicated.txt"
```

Without `--output`, the symbolicated report is printed to standard output.

## Reading the result

- `Thread N [attributed/crashed]` identifies the thread MetricKit attributed to
  the crash.
- Every available thread is included, not only the attributed thread.
- OsmAnd frames should contain function names and, when debug information is
  available, source file names and line numbers.
- `[no matching dSYM]` is expected for binaries whose dSYMs were not supplied,
  including many system frameworks. It should not appear on the relevant
  OsmAnd app or debug-dylib frames.
- The final `Resolved dSYMs for X/Y binary UUIDs` message reports UUID matches,
  not the number of symbolicated frames.

## Troubleshooting

### OsmAnd frames say `no matching dSYM`

The supplied archive, dSYM, or debug dylib does not match the crash UUID, or the
search path is wrong. Use the artifact preserved from the exact crashing build.
You can inspect a dSYM or binary UUID with:

```sh
xcrun dwarfdump --uuid "/path/to/OsmAnd Maps.app.dSYM"
```

For an `.xcarchive`, its dSYMs are inside the archive's `dSYMs` directory.

### Function names appear but source lines do not

The dSYM does not contain complete line-table information. For a debug dylib,
generate its dSYM before deleting the corresponding Xcode build products and
intermediate object files.

### The script reports `no MetricKit callStackTree values found`

The JSON is not a MetricKit diagnostic containing a call-stack tree. Verify that
the selected file is an `osmand-crash-*.json` report and that it is not empty or
truncated.

### `xcrun` is unavailable

Install Xcode's command-line tools or select the installed Xcode:

```sh
sudo xcode-select --switch "/Applications/Xcode.app/Contents/Developer"
```

Then rerun the command.
