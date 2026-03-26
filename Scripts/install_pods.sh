#!/bin/bash
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$SRCLOC/.."
POD=`which pod`
PATCH=`which patch`

apply_patch_file() {
	local patch_file="$1"

	if "$PATCH" --dry-run --directory="$REPO_ROOT" -p1 -N -f -i "$patch_file" >/dev/null 2>&1; then
		"$PATCH" --directory="$REPO_ROOT" -p1 -N -f -i "$patch_file"
		return $?
	fi

	if "$PATCH" --dry-run --reverse --directory="$REPO_ROOT" -p1 -N -f -i "$patch_file" >/dev/null 2>&1; then
		echo "Patch $(basename "$patch_file") already applied, skipping"
		return 0
	fi

	echo "Patch $(basename "$patch_file") cannot be applied cleanly"
	return 1
}

apply_pod_patches() {
	local patch_dir="$SRCLOC/Pod-patches"
	local patch_file

	shopt -s nullglob
	local patch_files=("$patch_dir"/*.patch)
	shopt -u nullglob

	if [ ${#patch_files[@]} -eq 0 ]; then
		return 0
	fi

	echo "Applying pod patches"
	for patch_file in "${patch_files[@]}"; do
		echo "Applying $(basename "$patch_file")"
		if ! apply_patch_file "$patch_file"; then
			return 1
		fi
	done
}

if [ -z "$POD" ]; then
	echo "'pod' tool not found, run 'sudo gem install cocoapods'"
	exit 1
fi
if [ -z "$PATCH" ]; then
	echo "'patch' tool not found"
	exit 1
fi
if [[ ! -f "$REPO_ROOT/Podfile.lock" ]]; then
	echo "Installing dependencies via CocoaPods"
	(cd "$REPO_ROOT" && $POD install --repo-update)
else
	echo "Updating dependencies via CocoaPods"
	(cd "$REPO_ROOT" && $POD update)
fi
retcode=$?
if [ $retcode -ne 0 ]; then
	echo "Failed to processing dependencies via CocoaPods, aborting..."
	exit $retcode
fi

apply_pod_patches
retcode=$?
if [ $retcode -ne 0 ]; then
	echo "Failed to apply pod patches, aborting..."
	exit $retcode
fi
