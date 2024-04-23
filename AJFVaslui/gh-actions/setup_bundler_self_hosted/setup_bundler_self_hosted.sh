#!/bin/bash

set -e
set -u
set -o pipefail

# Set up Bundler for self-hosted runners by:
#   - Setting the path to ~/vendor/bundle
#   - Setting the Bundler groups to exclude and include
#   - Installing the gems from the Gemfile
#
# Accepts two arguments:
#   - $1: The Bundle groups to exclude that are by default not optional in the Gemfile
#   - $2: The Bundle groups to include that are by default optional in the Gemfile

WITHOUT_GROUP=$1
WITH_GROUP=$2

bundle config set --local path ~/vendor/bundle

if [ -n "${WITHOUT_GROUP}" ]; then
  bundle config set --local without "${WITHOUT_GROUP}"
else
  bundle config unset --local without
fi

if [ -n "${WITH_GROUP}" ]; then
  bundle config set --local with "${WITH_GROUP}"
else
  bundle config unset --local with
fi

bundle install
