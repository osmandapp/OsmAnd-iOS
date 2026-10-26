# Plan Route history UI tests (#5782)

`PlanRouteHistoryUITests` exercises the running app with XCUITest. Editing, point menus, Undo/Redo, map gestures, saving and reopening use the production UI. It does not import the app module or execute command/context methods from the test runner. The existing `OAPlanRouteHistoryTests` are separate unit tests.

Select the **OsmAnd Plan Route UI Tests** shared scheme and run Test in Xcode. This scheme selects only `PlanRouteHistoryUITests`; it does not run unit tests. Use a dedicated portrait iPhone simulator. The runner sets English/US explicitly so native menu and alert labels are deterministic.

This suite is currently local-only. The main **OsmAnd Maps** scheme skips `PlanRouteHistoryUITests`, so existing GitHub Actions commands do not pick it up. No workflow or build gate is changed. Enabling it in CI requires a separate stability check on the intended runner.

Xcode test enumeration on 2026-10-26 confirmed that the main scheme with `-only-testing:OsmAnd MapsUITests` disables all 18 Plan Route tests and keeps both existing context-menu tests enabled.

For a command-line run, replace `SIMULATOR_ID` with the intended simulator identifier:

```sh
xcodebuild test \
  -workspace OsmAnd.xcworkspace \
  -scheme 'OsmAnd Plan Route UI Tests' \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=SIMULATOR_ID' \
  -parallel-testing-enabled NO \
  -collect-test-diagnostics never \
  -resultBundlePath /tmp/PlanRouteHistory.xcresult \
  CODE_SIGNING_ALLOWED=NO
```

The command disables slow system-wide failure diagnostics; test screenshots, failure hierarchies and assertions remain in the result bundle.

Use an isolated simulator when validating a new build. A local CoreSimulator run loaded an obsolete test library from its `Dead` cache despite the updated installed bundle. That run was discarded. Erasing and rebooting only the dedicated test simulators resolved it; their loaded test-library hashes then matched the build. Such an environment failure must not be reported as an app regression.

The result bundle contains screenshots and JSON renderer snapshots at initial/final checkpoints and on failures. Each independent scenario launches a fresh editing session. Source fixtures use `UITest-5782-source-<UUID>.gpx` names in the dedicated simulator's GPX directory. Save-as-copy uses the application's unique suggested filename, which is recorded in an attachment. These identified test artifacts remain in that simulator for inspection; no existing track is overwritten. Preparation hides previously visible tracks with this test-only prefix and seeds the map near the fixture, so prior saved copies and camera positions do not become starting conditions.

## Coverage

The identifiers match [Testing 2 in #5782](https://github.com/osmandapp/OsmAnd-iOS/issues/5782#issuecomment-6083116184). There are 18 test methods because TP-08 has separate Apply and Cancel tests. TP-04, TP-05 and TP-06 each run both Trim directions.

| Case | Automated checks |
| --- | --- |
| TP-01 / TP-02 | Trim before/after, retained coordinates/order, Undo/Redo, exact line geometry after pan/zoom |
| TP-03 | Two trims and repeated independent six-/four-point history states |
| TP-04 / TP-05 / TP-06 | One/three/two additions, every Undo/Redo state, final Undo and map gestures |
| TP-07 | Delete/insert in the middle, original suffix, distinct added point, line color, history |
| TP-08 | Add one more twice; Apply commits the pending third point; Cancel preserves only the two committed additions; history |
| TP-09 | Delete segment endpoint; Undo restores the original point and exactly one gap |
| TP-10 | Repeated Trim/Clear history restores detailed geometry; empty state has no committed lines |
| TP-11 | Reverse order; repeated Undo restores original geometry; save/reopen a new copy |
| TP-12 / TP-13 | Join from either segment boundary; menu availability after history; original gap and geometry restored |
| TP-14 | Eight/one/zero-point transitions and absence of obsolete committed lines |
| TP-15 | Save/reopen after Redo Trim preserves only the retained coordinates and geometry |
| TP-16 | Map taps during Move; Cancel restores the original route; subsequent history contains only the ordinary addition |
| TP-17 | New route, three/two/three/two points, Close/Discard returns to the map |

## Fixtures and observation boundary

`PlanRouteHistoryFixture` generates GPX XML in memory before each scenario. No GPX files are bundled or read from the developer's machine. The test runner passes the XML through the launch environment; Debug-only preparation writes a uniquely named file inside the simulator app's GPX directory and opens it through the existing track-loading path.

Both variants have eight named, distinct editable route points (P1–P8), using the default straight-line profile. The geometry variant also generates 29 samples and seven synthetic precomputed route segments with bends. Each leg includes its endpoint; duplicated boundary samples are intentional. Comparisons remove consecutive identical renderer coordinates because they describe the same drawn geometry. Coordinates use the exporter's seven-decimal precision and the POSIX locale. The GPX namespace is the standard HTTP namespace identifier, not a network request; the HTTPS lint rule exempts only this exact namespace.

No map download or live road calculation is required. These fixtures test preservation of already loaded geometry. They do **not** validate car/bicycle routing, actual road adherence, online services, in-flight routing cancellation, or recorded-track metadata.

`-ui-testing` plus `-ui-testing-plan-route-history` enables Debug-only fixture preparation and a read-only accessibility state element. The app target's Debug configuration defines `OSMAND_UI_TESTING` for the Swift probe; Release and Nightly omit it. It reads actual editable coordinates/gaps and the measurement layer's live committed `VectorLinesCollection`, including line colors, plus the current map target and zoom. Pan/zoom assertions verify an actual camera change. The runner cannot mutate that state. Other accessibility identifiers identify normal UI controls.

The geometry assertions detect obsolete committed renderer lines and lost/restored bends. They do **not** inspect GPU pixels or the separate provisional crosshair line. Screenshots are attached for visual review; raster artifacts, theme-specific appearance, landscape/iPad layout and physical-device behavior need separate verification.

## Verification status

Verified locally on 2026-10-26 with Xcode 26.6 (17F113), iOS 26.5 and two dedicated iPhone 17 simulators:

Source base: local `r5.4` at `016e64528d`, plus this change. The Debug bundle reports version `4.7.4` / build `4.7.4.2`, which are the existing project defaults; no release version override was supplied.

- Full application and UI-test `build-for-testing`: passed.
- All 18 current test methods: passed, zero failures and zero skips. Two disjoint groups of nine ran on the same build, with generated GPX data and verified loaded test binaries. Result bundles: `Clean-A-05.xcresult` and `Clean-B-05.xcresult`.
- SwiftLint strict checks for all eight changed/new Swift files: passed. The declaration-order checker reports only the existing `overridesMapPosition` property-order warning in `PlanRouteScrollableViewController`, also present in the base revision.
- Project/scheme XML validation, absence of bundled GPX/local Downloads references, and `git diff --check`: passed.

This confirms the local scenarios on that environment. CI stability, other OS versions and the visual limitations above remain unverified.
