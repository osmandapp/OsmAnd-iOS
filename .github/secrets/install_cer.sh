#!/bin/sh
set -eo pipefail

gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output ./.github/secrets/Github_Build.mobileprovision.mobileprovision ./.github/secrets/Github_Build.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output ./.github/secrets/osmand_distribution.p12 ./.github/secrets/osmand_distribution.p12.gpg

# KEYCHAIN_PATH=$RUNNER_TEMP/<keychain name>
KEYCHAIN_PATH=~/Library/Keychains/login.keychain-db

security unlock-keychain -p ${USER_KEY} $KEYCHAIN_PATH

# - security import ./.github/secrets/osmand_distribution.p12 -t agg -k ~/Library/Keychains/build.keychain -P "$PASSWORD_KEYCHAIN_EXPORT" -A
security import ./.github/secrets/osmand_distribution.p12 -P "$PASSWORD_KEYCHAIN_EXPORT" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH

cp ./.github/secrets/Github_Build.mobileprovision.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/Github_Build.mobileprovision
