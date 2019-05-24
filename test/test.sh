#! /bin/bash

# Setup
cd test-project
bundle

# Test ios_hotfix_prechecks
git tag 10.1
bundle exec fastlane run ios_hotfix_prechecks version:10.1.1 skip_confirm:true
git tag -d 10.1


# Test ios_bump_version_hotfix
CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
git tag 10.1
bundle exec fastlane run ios_bump_version_hotfix previous_version:10.1 version:10.1.1
git checkout $CURRENT_BRANCH
git tag -d 10.1
git push origin --delete "release/10.1.1"
git branch -D "release/10.1.1"
