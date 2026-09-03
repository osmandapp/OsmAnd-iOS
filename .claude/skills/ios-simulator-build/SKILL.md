---
name: ios-simulator-build
description: Build OsmAnd Maps for the iOS Simulator, install it, launch it, and (optionally) record a short startup/demo video with simctl. Use whenever asked to build/run/test the iOS app on a simulator, or to record a video/screenshot of iOS app behavior.
---

# iOS Simulator build, run, and record

Workspace: `ios/OsmAnd.xcworkspace`, scheme `"OsmAnd Maps"`. Build products live in
`ios/DerivedData` (repo-local on purpose, so a rebuild in a later session/checkout is
incremental instead of from scratch — always pass `-derivedDataPath`, never the default
`~/Library/Developer/Xcode/DerivedData/...`).

## Quick path (once the repo is in a known-good state)

```bash
cd ios
xcrun simctl list devices | grep Booted   # reuse an already-booted sim if one exists
xcodebuild -workspace OsmAnd.xcworkspace -scheme "OsmAnd Maps" -configuration Debug \
  -destination 'platform=iOS Simulator,id=<udid>' \
  -derivedDataPath "$(pwd)/DerivedData" build
xcrun simctl install <udid> "DerivedData/Build/Products/Debug-iphonesimulator/OsmAnd Maps.app"
xcrun simctl launch <udid> net.osmand.maps
```

To record a startup video (works with plain sandboxed Bash, no `dangerouslyDisableSandbox`,
no macOS Screen Recording permission — this records from the simulator process itself):

```bash
xcrun simctl terminate <udid> net.osmand.maps 2>/dev/null   # so the recording catches a real launch
sleep 1
xcrun simctl io <udid> recordVideo out.mov &
REC_PID=$!
sleep 1
xcrun simctl launch <udid> net.osmand.maps
sleep 6                # or however long you need
kill -INT $REC_PID
sleep 1.5               # let it flush to disk
```

Then `open -R "$(pwd)/out.mov"` to reveal it in Finder (needs `dangerouslyDisableSandbox: true`
for the Bash call — that's a GUI/Finder action, not a build/simctl one).

## One-time repairs (only needed once per broken/fresh checkout — check for the specific error first)

1. **`'libxslt/documents.h' file not found`** (BRCybertron target) → run
   `Scripts/download_libxslt_for_BRCybertron_spm.sh` from `ios/`.

2. **`Build input file cannot be found: .../core/src/...`** → the cmake-generated core Xcode
   project at `repos/baked/fat-ios-clang.xcode` has drifted from `core/src`. Regenerate it
   (cheap, ~15s, just cmake configure — NOT the full Qt rebuild):
   ```bash
   cd ios && OSMAND_BUILD_TOOL=xcode ../build/fat-ios.sh
   ```
   Don't run the full `prepare.sh` for this — it also wipes Pods/Podfile.lock.

3. **A compile error inside `core/externals/<name>/upstream.patched/<file>` that looks like an
   ancient-Mac-OS compat shim breaking under a newer SDK** (e.g. `TARGET_OS_MAC`-gated code,
   missing headers like `fp.h`): check `core/externals/<name>/patches/` first — there is
   probably already a patch for it that just isn't reflected in the current `upstream.patched/`
   (a known repo gap: `patches/` can gain a new file without the `stamp`/`.stamp` pair being
   bumped, so a local checkout's `upstream.patched/` silently goes stale). Force a clean
   reapply rather than hand-editing:
   ```bash
   EXT=/Users/victorshcherb/osmand/repos/core/externals/<name>
   rm -rf "$EXT/upstream.patched"
   cp -rfp "$EXT/upstream.original" "$EXT/upstream.patched"
   patch --strip=1 --directory="$EXT/upstream.patched/" --input="$EXT/patches/<file>.patch"
   ```
   `--input` must be an **absolute** path — `--directory` chdirs first, so a relative path
   resolves against the wrong place. Only touch the external actually implicated by a real
   build error; don't preemptively re-patch everything.
   Confirmed needed for **zlib** (`1-clang17.patch`) and **libpng** (`clang17.patch`) against
   iOS SDK 26.5 on 2026-09-03.

4. **`xcodebuild -showdestinations` / `-showsdks` shows a much newer SDK than any installed
   simulator runtime, and every simulator device is `unavailable, runtime profile not found
   using "System" match policy"`** — usually right after an Xcode update. `xcodebuild
   -downloadPlatform iOS` can pull a runtime build that the SDK's match policy then rejects
   (disk image shows "Ready" in `xcrun simctl runtime list` but no device becomes available,
   and `simctl runtime match set <sdk> <build>` overrides + CoreSimulatorService restarts don't
   fix it either). **Use Xcode's own GUI instead**: Xcode → Settings → Platforms → "Get" on the
   iOS Simulator row. It fetches the exact matching build and registers cleanly. Old simulator
   devices bound to the previous runtime stay `unavailable` — just boot one of the new devices
   Xcode auto-creates (e.g. "iPhone 17") or `simctl create` a fresh one on the new runtime.

5. **`Failed to launch AssetCatalogSimulatorAgent via CoreSimulator spawn` /
   `Failed to open FIFOs for handshaking with platform tool`** on every
   `CompileAssetCatalog(Variant)` step, regardless of sandbox/destination/`ENABLE_ON_DEMAND_RESOURCES`
   flags or CoreSimulatorService restarts — this is Xcode being too old for the installed macOS.
   Only real fix: update Xcode (App Store).

If you hit an error not listed here, don't assume it's environmental — check
`core/externals/<name>/patches/` per point 3 before writing a new fix; several of these SDK-bump
errors already have a patch sitting unapplied in the repo.
