# App Store metadata

The current `metadata.md` is a public-storefront draft for 21 locales. The
publishing lane rejects its draft marker. Before publishing, compare it with
App Store Connect, especially the Indonesian and Norwegian text and the blank
Promotional Text fields.

For a one-time App Store Connect import, run **GitHub → Actions → Import App
Store Metadata → Run workflow** once from `master`. Download the
`app-store-metadata-for-review` artifact, review its `metadata.md`, and add the
reviewed file to this repository. This workflow only reads App Store Connect;
it does not publish or commit metadata.

Before running either workflow, configure the `app-store-metadata` GitHub
Environment with a required reviewer and protect release branches. The workflows
use the existing `PUBLISH_BUILD_SECRET`, `PUBLISH_BUILD_KEY_ID`, and
`PUBLISH_BUILD_ASC_ISSUER_ID` secrets.

1. Edit `app-store/metadata.md` and commit or merge the change.
2. Keep `@localization(help_what_is_new)` unchanged in every language.
3. Open **GitHub → Actions → App Store Metadata → Run workflow** and select
   the current release branch (for example, `r5.4` or `r5.5`).
4. **What's New** is checked by default. Check any other fields you want to publish.
5. If validation fails, correct the locale and field named in the error, then run it again.

When validation succeeds, the workflow publishes only the checked fields. Keywords are not managed here.
