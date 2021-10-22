#!/bin/bash -eu

echo "--- :beer: Installing Dependencies"
brew bundle --file .buildkite/brewfile

echo "--- :rubygems: Setting up Gems"
install_gems
