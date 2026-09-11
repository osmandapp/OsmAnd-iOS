#!/bin/zsh

set -euo pipefail

input_binary="${1:-${HOME}/Downloads/OsmAnd Maps.debug.dylib}"
output_dsym="${2:-${input_binary}.dSYM}"

if [[ ! -f "${input_binary}" ]]; then
    print -u2 "error: input binary does not exist: ${input_binary}"
    exit 2
fi

if [[ -e "${output_dsym}" ]]; then
    print -u2 "error: output already exists: ${output_dsym}"
    print -u2 "Move or delete it before running this script again."
    exit 2
fi

if ! command -v xcrun >/dev/null 2>&1; then
    print -u2 "error: xcrun is unavailable; install or select Xcode command-line tools."
    exit 2
fi

print "Building dSYM..."
xcrun dsymutil "${input_binary}" -o "${output_dsym}"

input_uuids="$(xcrun dwarfdump --uuid "${input_binary}" | sed -E 's/^UUID: ([^ ]+).*/\1/' | sort)"
output_uuids="$(xcrun dwarfdump --uuid "${output_dsym}" | sed -E 's/^UUID: ([^ ]+).*/\1/' | sort)"

if [[ -z "${input_uuids}" || "${input_uuids}" != "${output_uuids}" ]]; then
    print -u2 "error: generated dSYM UUIDs do not match the input binary."
    print -u2 "Input UUIDs:"
    print -u2 "${input_uuids:-<none>}"
    print -u2 "dSYM UUIDs:"
    print -u2 "${output_uuids:-<none>}"
    exit 1
fi

print "dSYM created successfully:"
print "${output_dsym}"
print "UUIDs:"
print "${output_uuids}"
print
print "Symbolicate a report with:"
print "python3 \"${0:A:h}/symbolicate_metrickit.py\" <crash-report.json> --archives \"${output_dsym}\" --no-spotlight"
