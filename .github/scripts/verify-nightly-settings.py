import json
import sys


def main():
    config, expected_bundle, expected_icon = sys.argv[1:]
    entries = json.load(sys.stdin)
    matches = [entry for entry in entries if entry.get("target") == "OsmAnd Maps"]
    if len(matches) != 1:
        targets = ", ".join(entry.get("target", "<unknown>") for entry in entries)
        sys.exit(f"{config}: expected one OsmAnd Maps target, found {len(matches)} (targets: {targets})")

    settings = matches[0]["buildSettings"]
    for key, expected in (
        ("PRODUCT_BUNDLE_IDENTIFIER", expected_bundle),
        ("ASSETCATALOG_COMPILER_APPICON_NAME", expected_icon),
    ):
        actual = settings.get(key, "")
        if actual != expected:
            sys.exit(f"{config} {key} is {actual!r}, expected {expected!r}")


if __name__ == "__main__":
    main()
