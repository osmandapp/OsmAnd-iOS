# Plan Route history UI tests (#5782)

`PlanRouteHistoryUITests` exercises the running app with XCUITest. Editing, point menus, Undo/Redo, map gestures, saving and reopening use the production UI. It does not import the app module or execute command/context methods from the test runner. The existing `OAPlanRouteHistoryTests` are separate unit tests.

Use the existing **OsmAnd Maps** shared scheme and **OsmAnd MapsUITests** target. It includes the 18 Plan Route history tests and both existing context-menu tests. There is no separate Plan Route scheme. Use a dedicated portrait iPhone simulator. The runner sets English/US explicitly so native menu and alert labels are deterministic.

The existing GitHub Actions UI-test commands use `-scheme 'OsmAnd Maps' -only-testing:OsmAnd MapsUITests`, so they include these tests automatically. This change preserves the existing workflow schedules, opt-in settings and build gates.

For a command-line run, replace `SIMULATOR_ID` with the intended simulator identifier:

```sh
xcodebuild test \
  -workspace OsmAnd.xcworkspace \
  -scheme 'OsmAnd Maps' \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=SIMULATOR_ID' \
  '-only-testing:OsmAnd MapsUITests' \
  -testLanguage en \
  -testRegion US \
  -parallel-testing-enabled NO \
  -collect-test-diagnostics never \
  -resultBundlePath /tmp/PlanRouteHistory.xcresult \
  CODE_SIGNING_ALLOWED=NO
```

The command runs all 20 UI tests without unit tests. It disables slow system-wide failure diagnostics; test screenshots, failure hierarchies and assertions remain in the result bundle. Choose a fresh result-bundle path for each run. To run only the Plan Route cases, use `-only-testing:OsmAnd MapsUITests/PlanRouteHistoryUITests` with the same scheme.

Use an isolated simulator when validating a new build. A local CoreSimulator run loaded an obsolete test library from its `Dead` cache despite the updated installed bundle. That run was discarded. Erasing and rebooting only the dedicated test simulators resolved it; their loaded test-library hashes then matched the build. Such an environment failure must not be reported as an app regression.

The result bundle contains screenshots and JSON renderer snapshots at initial/final checkpoints and on failures. Each independent scenario launches a fresh editing session. Source fixtures use `UITest-5782-source-<UUID>.gpx` names in the dedicated simulator's GPX directory. Save-as-copy uses the application's unique suggested filename, which is recorded in an attachment. These identified test artifacts remain in that simulator for inspection; no existing track is overwritten. Preparation hides previously visible tracks with this test-only prefix and seeds the map near the fixture, so prior saved copies and camera positions do not become starting conditions.

## Coverage

The identifiers match [Testing 2 in #5782](https://github.com/osmandapp/OsmAnd-iOS/issues/5782#issuecomment-6083116184). There are 18 test methods because TP-08 has separate Apply and Cancel tests. TP-04, TP-05 and TP-06 each run both Trim directions.

| Case | Automated checks |
| --- | --- |
| TP-01 / TP-02 | Trim before/after, retained coordinates/order, Undo/Redo, exact line geometry after pan/zoom |
| TP-03 | Two trims and repeated independent six-/four-point history states |
| TP-04 / TP-05 / TP-06 | One/three/two additions, every Undo/Redo state, final Undo and map gestures |
| TP-07 | Delete/insert in the middle, exact curved geometry of the unchanged prefix/suffix, distinct added point, line color, history and map gestures |
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

Both variants have eight named, distinct editable route points (P1–P8), using the default straight-line profile. The geometry variant also generates 29 samples and seven synthetic precomputed route segments with bends. Each leg includes its endpoint; duplicated boundary samples are intentional. Comparisons remove consecutive identical renderer coordinates because they describe the same drawn geometry. Coordinates use the exporter's seven-decimal precision and the POSIX locale. The GPX namespace is the standard HTTP namespace identifier, not a network request; the UI-test directory’s SwiftLint configuration exempts only this exact namespace from the HTTPS rule. The root SwiftLint rule is unchanged.

No map download or live road calculation is required. These fixtures test preservation of already loaded geometry. They do **not** validate car/bicycle routing, actual road adherence, online services, in-flight routing cancellation, or recorded-track metadata.

`-ui-testing` plus `-ui-testing-plan-route-history` enables Debug-only fixture preparation and a read-only accessibility state element. The Swift probe uses the standard `DEBUG` condition, matching the Objective-C fixture and snapshot guards. The app target's Debug configuration defines `DEBUG` for Swift as well as Objective-C; Release and Nightly omit it. `PlanRouteUITestStateView.swift` lives alongside the Plan Route controller, while `UITestState.swift` only manages launch arguments and fixture state. The probe reads actual editable coordinates/gaps and both measurement-layer `VectorLinesCollection` instances (committed route and provisional crosshair lines), including line colors, plus the current crosshair, map target and zoom. Pan/zoom assertions verify an actual camera change. The runner cannot mutate that state. Other accessibility identifiers identify normal UI controls.

The geometry assertions detect obsolete committed renderer lines and lost/restored bends. Outside an active point edit, state waits also require exactly the current endpoint-to-crosshair line, or no provisional line for an empty route or gap endpoint. This checks `_lastLineCollection` after history and map gestures without treating the legitimate crosshair preview as a stale route line. They do **not** inspect GPU pixels. Screenshots are attached for visual review; raster artifacts, theme-specific appearance, landscape/iPad layout and physical-device behavior need separate verification.

## Review follow-up verification (2026-10-29)

The probe now uses `DEBUG` and lives in a separate Plan Route source file. The GPX namespace lint exception is confined to this UI-test directory.

- Targeted iOS SDK type checks for the extracted view and launch-state helpers passed with and without `DEBUG`. Swift parsing passed for the affected controller in both configurations.
- Project validation confirmed that the new file belongs to the app target and Swift `DEBUG` is enabled only in Debug. Release and Nightly omit it.
- SwiftLint across the nine affected Swift files reports the same six existing violations; the declaration-order checker reports the same 49 existing warnings. The extracted view has no violations.
- A focused lint check confirmed that the exact GPX namespace is exempt only in UI tests, while ordinary HTTP URLs and near-matching namespaces remain reported.
- `git diff --check` passed. No full application build or UI-test run was performed for this follow-up; the runtime results below apply to the earlier revision.

## Master integration verification

Verified locally on 2026-10-27 with Xcode 26.6 (17F113), iOS 26.5 and a dedicated iPhone 17 simulator. Source base: `master` at `c17257d579`, plus this change. The test sources match the reviewed r5.4 revision `35eb4ffe4f`; this integration preserves all assertions.

- Full `build-for-testing` through the existing **OsmAnd Maps** scheme: passed in 15 minutes 39.37 seconds.
- A single sequential run of the complete **OsmAnd MapsUITests** target: all 20 tests passed, zero failures and zero skips. This includes all 18 Plan Route tests and both existing context-menu tests.
- Total test-command duration: 21 minutes 10.90 seconds, excluding compilation. Result bundle: `All-UI.xcresult`.
- Loaded app and UI-test binary hashes matched the new build.
- Project/scheme validation and `git diff --check`: passed. No separate scheme, test exclusions or workflow changes were introduced.
- SwiftLint reports six existing violations in `PlanRouteToolbarsView` and `PlanRouteScrollableViewController`; comparison with the base revision found no new violations. The declaration-order checker reports the same 49 existing warnings as the base revision.

The existing GitHub Actions selection was checked in the workflow source. This integration has not yet been run on GitHub Actions; other OS versions and the visual limitations above remain unverified.

## Previous r5.4 verification

Verified locally on 2026-10-26 with Xcode 26.6 (17F113), iOS 26.5 and two dedicated iPhone 17 simulators:

Source base: local `r5.4` at `016e64528d`, plus this change. The Debug bundle reports version `4.7.4` / build `4.7.4.2`, which are the existing project defaults; no release version override was supplied.

- Full application and UI-test `build-for-testing`: passed.
- All 18 test methods at that revision: passed, zero failures and zero skips. Two disjoint groups of nine ran on the same build, with generated GPX data and verified loaded test binaries. Result bundles: `Clean-A-05.xcresult` and `Clean-B-05.xcresult`.
- SwiftLint strict checks for all eight changed/new Swift files: passed. The declaration-order checker reports only the existing `overridesMapPosition` property-order warning in `PlanRouteScrollableViewController`, also present in the base revision.
- Project/scheme XML validation, absence of bundled GPX/local Downloads references, and `git diff --check`: passed.

The follow-up review changes also passed all 18 Plan Route tests in a single local run on 2026-10-27, with a total command duration of 30 minutes 4.32 seconds, excluding compilation. These results describe the previous r5.4 branch, not verification of the master integration. CI stability, other OS versions and the visual limitations above remain unverified.
