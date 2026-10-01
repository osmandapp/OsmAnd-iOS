# App Store metadata

`metadata.md` was imported from the production App Store Connect app for 21 locales.
Review any edits before publishing them.

The publishing workflow currently targets **OsmAnd Nightly**
(`net.osmand.maps.nightly`) for testing. It publishes selected fields for **all
21 locales** in `metadata.md`, creating missing App Info and App Store version
localizations in Nightly first. The checked **What's New** field uses the iOS
localization text for version 5.4, because Nightly's editable version is 1.0.
Apple requires an app name when a new App Info localization is created. When
Title is unchecked, the workflow uses Nightly's existing primary app name for
new locales. Production Titles in `metadata.md` already belong to the main app,
so the Title checkbox is blocked for Nightly until Nightly-specific names are
provided. Existing app names are not changed when Title is unchecked.
Some of the 21 locales do not yet have `ios_release_5_4`; selecting **What's New**
will fail validation before any localization is created or text uploaded until
those translations are present. For Description-only publishing, uncheck
**What's New**. Change the target app and release-note source in the Fastlane
configuration when moving this workflow to production.

Before running the workflow, configure the `app-store-metadata` GitHub
Environment with a required reviewer and protect the allowed branches. The workflow
uses the existing `PUBLISH_BUILD_SECRET`, `PUBLISH_BUILD_KEY_ID`, and
`PUBLISH_BUILD_ASC_ISSUER_ID` secrets.

1. Edit `app-store/metadata.md` and commit or merge the change.
2. Keep `@localization(help_what_is_new)` unchanged in every language.
3. Open **GitHub → Actions → App Store Metadata → Run workflow** and select
   `master` for the Nightly trial or a release branch (for example, `r5.4`).
4. **What's New** is checked by default. Check any other fields you want to publish.
5. If validation fails, correct the locale and field named in the error, then run it again.

When validation succeeds, the workflow publishes only the checked fields.
Keywords are not managed here.
