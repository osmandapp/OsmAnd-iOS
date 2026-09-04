# Release automation

The build stays in `xcodebuild` (see `.github/workflows/xcode-local-build.yml`). Fastlane is
used only for App Store Connect, because `altool` can upload a binary but cannot set release
notes.

## Where release notes come from

They are not written for the store separately. The App Store text **is** the in-app
"What's new" string:

```
Resources/Localizations/<lang>.lproj/Localizable.strings
"ios_release_5_4" = "• Added \"Terrain shadows\" visualization type\n…";
```

`Scripts/generate_release_notes.rb 5.4.0` reads that key from every `.lproj`, maps the
language to its App Store Connect locale and writes
`fastlane/metadata/<locale>/release_notes.txt`. Languages that are not translated yet are
simply skipped — the App Store falls back to `en-US` for them. Re-running the
**App Store release notes** workflow after Weblate delivers more translations fills them in.

`fastlane/metadata/` is generated, so it is not committed.

## Workflows

| Workflow | What it does |
| --- | --- |
| **Build OsmAndMaps (self hosted)** | Builds, archives, exports the IPA and — if *Upload to TestFlight* is checked — uploads it with "What to Test" set. Always keeps the IPA as an artifact. |
| **Publish TestFlight (self hosted)** | Uploads an IPA an earlier build run produced. Takes that run's ID, so a build can be checked first and shipped later without rebuilding. |
| **App Store release notes** | Pushes the localized release notes for a version to App Store Connect. No build, no binary upload. |

## Lanes

```sh
fastlane release_notes version:5.4.0                  # generate fastlane/metadata only
fastlane beta version:5.4.0                           # TestFlight upload + "What to Test"
fastlane release version:5.4.0                        # localized release notes -> App Store
fastlane release version:5.4.0 submit_for_review:true # and submit the version for review
```

## Credentials

An App Store Connect API key is used when these secrets exist, and is the recommended setup —
it does not expire and is not tied to a personal Apple ID with 2FA:

- `ASC_KEY_ID` — the key ID
- `ASC_ISSUER_ID` — the issuer ID from App Store Connect → Users and Access → Integrations
- `ASC_KEY_P8` — the `.p8` private key, base64 encoded (`base64 -i AuthKey_XXXX.p8 | pbcopy`)

Without them fastlane falls back to the Apple ID and app-specific password already stored as
`APPLEID_USERNAME` / `APPLEID_PASSWORD`.
