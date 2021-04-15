#!/bin/sh
set -eo pipefail

gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output ./.github/secrets/Github_Build.mobileprovision.mobileprovision ./.github/secrets/Github_Build.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output ./.github/secrets/osmand_distribution.p12 ./.github/secrets/osmand_distribution.p12.gpg

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

cp ./.github/secrets/Github_Build.mobileprovision.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/Github_Build.mobileprovision.mobileprovision


security create-keychain -p "" build.keychain
security import ./.github/secrets/osmand_distribution.p12 -t agg -k ~/Library/Keychains/build.keychain -P "$PASSWORD_KEYCHAIN_EXPORT" -A

security list-keychains -s ~/Library/Keychains/build.keychain
security default-keychain -s ~/Library/Keychains/build.keychain
security unlock-keychain -p "" ~/Library/Keychains/build.keychain

security set-key-partition-list -S apple-tool:,apple: -s -k "" ~/Library/Keychains/build.keychain
