#!/bin/sh
set -eo pipefail

gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output ./.github/secrets/Github_Build.mobileprovision.mobileprovision ./.github/secrets/Github_Build.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output ./.github/secrets/osmand_distribution.p12 ./.github/secrets/osmand_distribution.p12.gpg


# KEYCHAIN_PATH=$RUNNER_TEMP/<keychain name>
KEYCHAIN_PATH=$RUNNER_TEMP/github_action.keychain

# - security create-keychain -p "" build.keychain
security create-keychain -p "$PASSWORD_KEYCHAIN_EXPORT" $KEYCHAIN_PATH

# - 
security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
# - security unlock-keychain -p "" ~/Library/Keychains/build.keychain
security unlock-keychain -p "$PASSWORD_KEYCHAIN_EXPORT" $KEYCHAIN_PATH

# - security import ./.github/secrets/osmand_distribution.p12 -t agg -k ~/Library/Keychains/build.keychain -P "$PASSWORD_KEYCHAIN_EXPORT" -A
security import ./.github/secrets/osmand_distribution.p12 -P "$PASSWORD_KEYCHAIN_EXPORT" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH

# - security list-keychains -s ~/Library/Keychains/build.keychain
# - security default-keychain -s ~/Library/Keychains/build.keychain
security list-keychain -d user -s $KEYCHAIN_PATH

#  - security set-key-partition-list -S apple-tool:,apple: -s -k "" ~/Library/Keychains/build.keychain

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp ./.github/secrets/Github_Build.mobileprovision.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/Github_Build.mobileprovision
