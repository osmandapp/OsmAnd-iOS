# App Store metadata: marketing guide

This repository is the source for five text fields in the main OsmAnd iOS app
(`net.osmand.maps`). [metadata.md](metadata.md) contains the reviewed copy for
21 App Store locales. Editing the file does not update App Store Connect by
itself: the **App Store Metadata** GitHub Actions workflow sends the selected
fields after the change has been merged.

## Edit the copy

Each locale starts with a heading such as `## en-US` or `## de-DE`. Keep locale
headings and field labels exactly as they are. The managed fields are:

| Field | Source | What it changes |
| --- | --- | --- |
| `Title` | `metadata.md` | App name |
| `Subtitle` | `metadata.md` | Subtitle |
| `Promotional Text` | `metadata.md` | Promotional text |
| `What's New` | iOS localization files | Release notes |
| `Description` | `metadata.md` | App description |

Edit the copy for every locale that needs a change. Descriptions can have
multiple paragraphs; the next locale starts at the next `##` heading. Check
translations, links, and App Store length limits before submitting a pull
request. An empty `Subtitle` or `Promotional Text` is allowed, but selecting
that field in the workflow sends the empty value to App Store Connect.

Leave `@localization(help_what_is_new)` unchanged under every `What's New`
heading. It is a marker for the script, not text sent to the store. The script
reads the release notes from each locale's iOS `Localizable.strings`, using the
editable App Store version to choose the key. For example, version 5.4.0 uses
`ios_release_5_4`, and version 5.5 uses `ios_release_5_5`. Coordinate changes
to release notes with the iOS team so the required key exists in every locale.

## Publish a change

1. Edit [metadata.md](metadata.md), review the copy, and create a pull request.
   Merge it into `master` or the intended release branch, such as `r5.4`.
2. Open **GitHub → Actions → App Store Metadata → Run workflow**. Select the
   branch containing the merged copy. The workflow accepts `master` and release
   branches named like `r5.4` or `r5.5`.
3. Check only the fields you want to sync. **What's New is checked by default**.
   For a Description-only update, uncheck **What's New** and check
   **Description**. Select at least one field.
4. Run the workflow. Read its summary and log for the target app, selected
   fields, and updated locales. Verify the result in the editable version of
   the main OsmAnd app in App Store Connect.

**A selected field is sent for all 21 locales in `metadata.md`**, including
locales whose text was not edited in the pull request. Unselected fields in
existing locales are left alone. If a locale is missing in App Store Connect,
the script creates it; Apple requires an app name for that operation, which
comes from that locale's `Title` in `metadata.md`.

The script validates all selected fields and all app names before sending
anything. If **What's New** is selected and a locale has no release-note key
for the editable version, validation stops the run before uploading. Uncheck
**What's New** when publishing other fields while release-note translations
are still being prepared.

If validation fails, fix the locale and field named in the error and rerun the
workflow. If an error occurs after upload begins, some locales may already be
updated. Check the `Updated` messages in the log and the values in App Store
Connect before rerunning.

The workflow updates metadata in App Store Connect. It does not upload a build
or submit the app for Apple review. It does not manage keywords, screenshots,
or prices. Access uses the protected `app-store-metadata` GitHub Environment;
marketers do not need the API key values. If a run waits for Environment
approval or reports an access error, contact the release owner.
