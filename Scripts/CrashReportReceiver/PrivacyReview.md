# Crash diagnostics privacy-review notes

Production upload is intentionally not configured by this change. Before the
release capture flag or a production endpoint is enabled, the privacy reviewer
should verify the serialized schema and approve the following external updates.

## Suggested public-policy wording

OsmAnd may keep a privacy-filtered diagnostic report on the device after a
crash, hang, resource exception, or enumerated recoverable error. A report is
not transmitted unless the user opens that report, reviews the exact diagnostic
payload, and selects **Send once**. If that approved upload is interrupted, the
same reviewed payload may be retried for up to seven days.

The report can contain the app/build and OS versions, hardware model, numeric
crash and termination codes, stack addresses and binary identifiers needed for
symbolication, coarse app-state categories, stable screen and event identifiers,
relative event times, and bucketed resource availability. It excludes precise
location, routes, searches, favorites, custom names, region identifiers, online
source URLs, file paths, logs, notification contents, account information,
stack memory, register dumps, and persistent device or installation identifiers.
Each report has an unrelated random identifier.

Crash diagnostics are used to investigate reliability and performance. They
are not used for tracking and are not linked to an identity. Production policy
wording must also state the server retention period, deletion process, access
controls, and contact channel once those values have been approved.

## App Store Connect answers

Declare these categories for diagnostics a user chooses to send:

- Crash Data
- Performance Data
- Other Diagnostic Data
- Product Interaction

For each category, select purposes matching app functionality and analytics,
and mark the data as not linked to the user's identity and not used for
tracking. The submitted answers must be checked against the final production
API, retention policy, and any authentication metadata before release.
