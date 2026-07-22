#!/bin/bash -e

# BRCybertron is now a local Swift package, but libxslt/libexslt are kept
# as downloaded build inputs instead of committed source trees.

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IOS_DIR="$(dirname "$SRCLOC")"

VERSION="1.1.34"
ARCHIVE_NAME="libxslt-$VERSION.tar.xz"
URL="https://builder.osmand.net/dependencies-mirror/$ARCHIVE_NAME"
TARGET_DIR="$IOS_DIR/Packages/BRCybertron/Sources/BRCybertron/libxslt"
SUPPORT_DIR="$IOS_DIR/Packages/BRCybertron/Support/libxslt"

if [ -f "$TARGET_DIR/libxslt/xslt.c" ] &&
   [ -f "$TARGET_DIR/libexslt/exslt.c" ] &&
   [ -f "$TARGET_DIR/libxslt/xsltconfig.h" ] &&
   grep -q "LIBXSLT_DOTTED_VERSION \"$VERSION\"" "$TARGET_DIR/libxslt/xsltconfig.h"; then
    echo "BRCybertron libxslt $VERSION sources already exist."
    exit 0
fi

TMP_ROOT="${TMPDIR:-/tmp}/osmand-brcybertron-libxslt-$$"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

download() {
    local from=$1
    local to=$2
    local attempt=0
    local exit_code=0

    while [ $attempt -lt 3 ]; do
        echo "Downloading $from to $to"
        if curl -L --fail "$from" -o "$to"; then
            return 0
        fi
        exit_code=$?
        attempt=$((attempt + 1))
        echo "Download failed, attempt $attempt"
        sleep 30
    done

    exit $exit_code
}

mkdir -p "$TMP_ROOT"
download "$URL" "$TMP_ROOT/$ARCHIVE_NAME"
tar -xf "$TMP_ROOT/$ARCHIVE_NAME" -C "$TMP_ROOT"

if [ ! -d "$TMP_ROOT/libxslt-$VERSION/libxslt" ] ||
   [ ! -d "$TMP_ROOT/libxslt-$VERSION/libexslt" ]; then
    echo "Error: libxslt/libexslt folders were not found in $ARCHIVE_NAME"
    exit 1
fi

rm -rf "$TARGET_DIR/libxslt" "$TARGET_DIR/libexslt"
mkdir -p "$TARGET_DIR"
cp -R "$TMP_ROOT/libxslt-$VERSION/libxslt" "$TARGET_DIR/"
cp -R "$TMP_ROOT/libxslt-$VERSION/libexslt" "$TARGET_DIR/"

cp "$SUPPORT_DIR/config.h" "$TARGET_DIR/config.h"
cp "$SUPPORT_DIR/xsltconfig.h" "$TARGET_DIR/libxslt/xsltconfig.h"
cp "$SUPPORT_DIR/exsltconfig.h" "$TARGET_DIR/libexslt/exsltconfig.h"

echo "BRCybertron libxslt $VERSION sources are ready."
