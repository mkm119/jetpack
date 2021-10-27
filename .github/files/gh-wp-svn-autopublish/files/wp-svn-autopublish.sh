#!/bin/bash

set -eo pipefail

: "${GITHUB_REF:?Build argument needs to be set and non-empty.}"
: "${WPSVN_USERNAME:?Build argument needs to be set and non-empty.}"
: "${WPSVN_PASSWORD:?Build argument needs to be set and non-empty.}"

## Determine tag
if ! [[ "$GITHUB_REF" =~ ^refs/tags/v[0-9]+(\.[0-9]+)+(-[a-z0-9._-]+)?$ ]]; then
	echo "::error::Expected GITHUB_REF like \`refs/tags/v1.2.3\`, got \`$GITHUB_REF\`"
	exit 1
fi
TAG="${GITHUB_REF#refs/tags/v}"

## Determine slug
WPSLUG=$(jq -r '.extra["wp-plugin-slug"] // ""' "src/composer.json")
if [[ -z "$WPSLUG" ]]; then
	echo '::error::Failed to determine plugin slug.'
	exit 1
fi

echo "Publishing $WPSLUG version $TAG"

mkdir svn
cd svn

echo '::group::Checking out SVN (shallowly)'
svn checkout "https://plugins.svn.wordpress.org/$WPSLUG/" --depth=empty .
echo '::endgroup::'

echo '::group::Checking out SVN trunk'
svn up trunk
echo '::endgroup::'

echo "::group::Checking out SVN tags (shallowly)"
svn up tags --depth=empty
echo '::endgroup::'

echo "::group::Deleting everything in trunk except for .svn directories"
find trunk ! \( -path '*/.svn/*' -o -path "*/.svn" \) \( ! -type d -o -empty \) -delete
[[ -e trunk ]] || mkdir -p trunk # If there were no .svn directories, trunk itself might have been removed.
echo '::endgroup::'

echo "::group::Copying git repo into trunk"
git clone ../src trunk/
echo '::endgroup::'

echo "::group::Removing .git files and empty directories"
find trunk -name '.git*' -print -exec rm -rf {} +
find trunk -type d -empty -print -delete
echo '::endgroup::'

echo "::group::Adding and removing SVN files"
while IFS=" " read -r FLAG FILE; do
	if [[ "$FLAG" == '!' ]]; then
		svn rm "$FILE"
	elif [[ "$FLAG" == "?" ]]; then
		svn add "$FILE"
	fi
done < <( svn status )
echo '::endgroup::'

echo "::group::Tagging release"
svn cp trunk "tags/$TAG"

# Update the stable tag in the tag if it's not a beta version.
if [[ "$TAG" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
	sed -i -e "s/Stable tag: .*/Stable tag: $TAG/" "tags/$TAG/readme.txt"
fi
echo '::endgroup::'

if [[ -n "$CI" ]]; then
	echo "::group::Committing to SVN"
	svn commit -m "Update to version $TAG from GitHub" --no-auth-cache --non-interactive  --username "$WPSVN_USERNAME" --password "$WPSVN_PASSWORD"
	echo '::endgroup::'
else
	echo "Not running in CI, skipping commit"
	echo "  svn commit -m \"Update to version $TAG from GitHub\" --no-auth-cache --non-interactive  --username \"$WPSVN_USERNAME\" --password \"$WPSVN_PASSWORD\""
fi
