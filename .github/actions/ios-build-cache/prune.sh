#!/bin/bash
set -euo pipefail

# Run after uploading the archive, before cache actions save their post-job state.
# Keep dependency objects/products, excluding app bundles and signing resources.
if [[ -n "${CI_DERIVED_DATA_PATH:-}" && -d "$CI_DERIVED_DATA_PATH" ]]; then
  rm -rf "$CI_DERIVED_DATA_PATH/Logs" "$CI_DERIVED_DATA_PATH/Index.noindex"
  find "$CI_DERIVED_DATA_PATH" -depth \( \
    -name '*.app' -o -name '*.appex' -o -name '*.xcarchive' -o \
    -name 'iTorrent.build' -o -name 'ProgressWidgetExtension.build' -o \
    -name 'InstallationBuildProductsLocation' -o \
    -name '*.mobileprovision' -o -name '*.xcent' -o -name '*.xcent.der' -o \
    -name 'GoogleService-Info.plist' \
  \) -exec rm -rf {} +
fi
