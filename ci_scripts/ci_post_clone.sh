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

echo "ci_post_clone: installing xcodegen"
brew install xcodegen

echo "ci_post_clone: generating CoScientist.xcodeproj from project.yml"
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "ci_post_clone: done"
