"""Let Gradle check the shared framework on every CI build, including tests."""

from pathlib import Path
import re


project = Path(__file__).resolve().parents[2] / "OsmAnd.xcodeproj/project.pbxproj"
source = project.read_text()
pattern = r"(\t\t[^\n]+ /\* Compile OsmAnd Shared Library \*/ = \{\n)(.*?)(\n\t\t\};)"
matches = list(re.finditer(pattern, source, re.DOTALL))
if len(matches) != 1:
    raise SystemExit("Expected exactly one Compile OsmAnd Shared Library build phase")

match = matches[0]
body, count = re.subn(r"buildActionMask = \d+;", "buildActionMask = 2147483647;", match[2])
if count != 1:
    raise SystemExit("Expected exactly one buildActionMask in the shared build phase")
body = re.sub(r"\n\t\t\talwaysOutOfDate = \d+;", "", body)
body += "\n\t\t\talwaysOutOfDate = 1;"
project.write_text(source[:match.start()] + match[1] + body + match[3] + source[match.end():])
print("Enabled Gradle framework checks for every CI build")
