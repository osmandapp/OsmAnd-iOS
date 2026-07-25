# OsmAnd iOS local crash-report receiver

This dependency-free server is for local development only. It accepts the
version 1, privacy-filtered upload contract and writes one pretty-printed JSON
file per `report_id`. It rejects unknown fields, known sensitive fields, paths,
URLs, oversized requests, and unsupported schema versions.

Start it for the iOS Simulator:

```sh
python3 receiver.py
```

The default endpoint is
`http://127.0.0.1:8080/api/v1/crash-reports`, and reports are written outside
the checkout to the system temporary directory under
`osmand-crash-reports`.

Open the human-readable reviewer at:

```text
http://127.0.0.1:8080/review
```

Drop an app-exported report or a JSON file saved by the receiver onto the page.
The report is parsed entirely in the browser: it is not uploaded, stored, or
modified. The readable view shows the crash summary, context, breadcrumbs, all
captured threads, and all binary images. The exact payload remains available
under the **Exact JSON** tab, with copy and download controls.

Check receiver readiness with:

```sh
curl http://127.0.0.1:8080/health
```

For a physical device, bind explicitly to all interfaces and set the
`OSMAND_CRASH_ENDPOINT` environment variable in the Debug run scheme to the
Mac's LAN address:

```sh
python3 receiver.py --host 0.0.0.0
OSMAND_CRASH_ENDPOINT=http://192.168.1.10:8080/api/v1/crash-reports
```

Only use the all-interfaces mode on a trusted test network. Release builds have
no endpoint and cannot upload. Release capture is also off unless the internal
`OSMAND_CRASH_CAPTURE_ENABLED` Info.plist flag is explicitly set after privacy
review.

## Manual end-to-end check

1. Start this receiver and run a Debug simulator build.
2. Open **Help → Crash diagnostics → Test crash**, choose one crash type, and
   relaunch the app without the debugger.
3. Open the non-blocking report banner and inspect the JSON. Choose **Later**,
   then revisit the same payload from **Help → Crash diagnostics**.
4. Verify **Delete** removes the local report without a request.
5. Generate another report, choose **Send once**, and verify one JSON file is
   written here. Reposting the same approved request must not create a second
   file.
6. Approve a report while the receiver is stopped, restart the receiver, and
   foreground the app to exercise retry of the unchanged reviewed payload.
7. Repeat with the Objective-C, C++, signal, and invalid-memory controls.

Before any production rollout, archive in the permitted build environment and
verify that the captured application binary UUID matches its dSYM UUID and that
the recorded offsets can be symbolicated. Production upload remains blocked
until authentication, retention, access control, and dSYM ingestion are
implemented.

The repository privacy manifest declares Crash Data, Performance Data, Other
Diagnostic Data, and Product Interaction as neither linked to identity nor
used for tracking. Before production upload is enabled, the matching App Store
Connect privacy answers and public privacy policy must be updated outside this
repository, and the production service must define authentication, retention,
access control, and dSYM handling.
