#!/bin/sh
#
# Xcode Cloud post-clone step.
#
# The CoScientist.xcodeproj is generated from project.yml by xcodegen and is gitignored
# (project.yml is the source of truth), so it must be regenerated after Xcode Cloud clones
# the repo, before the build/SwiftPM-resolution phase runs.
#
# Dependencies: every SwiftPM package this project uses is a PUBLIC https://github.com/...
# repository (apple/*, ml-explore/*, huggingface/*, swiftgraphs/Grape). None require
# authentication or credentials, so SwiftPM resolution in Xcode Cloud needs no secrets,
# no .netrc, and no SSH keys.
set -e

# Homebrew isn't always on PATH inside Xcode Cloud's ci_* scripts; add both Apple-silicon
# and Intel locations so `brew` and brew-installed tools resolve.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_AUTO_UPDATE=1

echo "ci_post_clone: installing xcodegen"
brew install xcodegen

echo "ci_post_clone: generating CoScientist.xcodeproj from project.yml"
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "ci_post_clone: generated; shared schemes:"
ls CoScientist.xcodeproj/xcshareddata/xcschemes/ || echo "WARNING: no shared schemes generated"

echo "ci_post_clone: done"
