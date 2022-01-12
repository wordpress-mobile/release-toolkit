#!/bin/bash -eu

echo "--- :hammer: Build Gemspec"
gem build fastlane-plugin-wpmreleasetoolkit.gemspec

echo "--- :sleuth_or_spy: Validate Gem Install"
gem install --user-install fastlane-plugin-wpmreleasetoolkit-*.gem

echo "--- :rubygems: Gem Push"
echo ":rubygems_api_key: ${RUBYGEMS_API_KEY}" >>".gem-credentials"
chmod 600 ".gem-credentials"
#gem push --config-file ".gem-credentials" fastlane-plugin-wpmreleasetoolkit-*.gem
