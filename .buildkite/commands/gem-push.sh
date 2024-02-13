#!/bin/bash -eu

GEM_NAME="fastlane-plugin-wpmreleasetoolkit"

echo "--- :hammer: Build Gemspec"
gem build "$GEM_NAME.gemspec" -o "$GEM_NAME.gem"

echo "--- :sleuth_or_spy: Validate Gem Install"
gem install --user-install "$GEM_NAME.gem"

echo "--- :rubygems: Gem Push"
echo ":rubygems_api_key: ${RUBYGEMS_API_KEY}" >>".gem-credentials"
chmod 600 ".gem-credentials"
gem push --config-file ".gem-credentials" "$GEM_NAME.gem"
