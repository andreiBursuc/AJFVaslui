#!/bin/bash

pushd .
CURRENT_DIR=$(cd "$(dirname "$0")" && pwd)
popd

GEMFILE_PATH="${CURRENT_DIR}/../../fastlane/Gemfile"
echo "Setting BUNDLE_GEMFILE=${GEMFILE_PATH}"
echo "OLD_BUNDLE_GEMFILE=${BUNDLE_GEMFILE}" >> $GITHUB_ENV
echo "BUNDLE_GEMFILE=${GEMFILE_PATH}" >> $GITHUB_ENV

POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  --bundle_with)
    echo "Setting BUNDLE_WITH=$2"
    echo "OLD_BUNDLE_WITH=$BUNDLE_WITH" >> $GITHUB_ENV
    echo "BUNDLE_WITH=$2" >> $GITHUB_ENV

    shift # past argument
    shift # past value
    ;;
  --bundle_without)
    echo "Setting BUNDLE_WITHOUT=$2"
    echo "OLD_BUNDLE_WITHOUT=$BUNDLE_WITHOUT" >> $GITHUB_ENV
    echo "BUNDLE_WITHOUT=$2" >> $GITHUB_ENV

    shift # past argument
    shift # past value
    ;;
  *) # unknown option
    echo "Unknown option $1"
    POSITIONAL_ARGS+=("$1") # save it in an array for later
    shift                   # past argument
    ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters
