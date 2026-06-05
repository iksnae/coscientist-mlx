#!/bin/sh
#
# Xcode Cloud post-clone step.
#
# The CoScientist.xcodeproj is generated from project.yml by xcodegen and is gitignored
# (project.yml is the source of truth), so it must be regenerated after Xcode Cloud clones
# the repo, before the build phase runs.
#
# We do NOT use Homebrew here: Xcode Cloud's build environment cannot reach ghcr.io
# (Homebrew's package host), so `brew install` fails with "Could not resolve host: ghcr.io".
# github.com IS reachable (that's how the repo + SwiftPM deps are fetched), so we download
# the prebuilt, self-contained xcodegen release binary from GitHub instead.
#
# Dependencies: every SwiftPM package this project uses is a PUBLIC https://github.com/...
# repository (apple/*, ml-explore/*, huggingface/*, swiftgraphs/Grape). None require
# authentication, so package resolution in Xcode Cloud needs no secrets, .netrc, or SSH keys.
set -e

XCODEGEN_VERSION="2.45.4"

echo "ci_post_clone: downloading xcodegen ${XCODEGEN_VERSION} from GitHub"
cd "$CI_PRIMARY_REPOSITORY_PATH"
rm -rf /tmp/xcodegen /tmp/xcodegen.zip
curl -fsSL -o /tmp/xcodegen.zip \
  "https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip"
unzip -q /tmp/xcodegen.zip -d /tmp   # extracts /tmp/xcodegen/bin/xcodegen (+ share/)

echo "ci_post_clone: generating CoScientist.xcodeproj from project.yml"
/tmp/xcodegen/bin/xcodegen generate --spec project.yml

echo "ci_post_clone: generated; shared schemes:"
ls CoScientist.xcodeproj/xcshareddata/xcschemes/ || echo "WARNING: no shared schemes generated"

echo "ci_post_clone: done"
