#!/usr/bin/env bash
# Builds an obfuscated release with the dart-defines from an env file.
#
#   scripts/build_release.sh appbundle            # Play Store bundle
#   scripts/build_release.sh apk                  # sideload / testing APK
#   scripts/build_release.sh ipa                  # App Store archive
#   scripts/build_release.sh appbundle .env.staging.json
#
# The env file (default .env.json, gitignored) is a JSON object of defines,
# for example:
#   {
#     "API_BASE_URL": "https://api.enjoylavash.uz",
#     "YANDEX_GEOCODER_KEY": "…",
#     "YANDEX_SUGGEST_KEY": "…",
#     "SENTRY_DSN": "…",
#     "APP_ENV": "production"
#   }
#
# Debug symbols are written to build/symbols/<target>. Keep them for every
# release (and upload them to Sentry) or obfuscated stack traces cannot be
# read.
set -euo pipefail

target="${1:-}"
env_file="${2:-.env.json}"

case "$target" in
  apk | appbundle | ipa) ;;
  *)
    echo "usage: $0 <apk|appbundle|ipa> [env-file]" >&2
    exit 64
    ;;
esac

if [[ ! -f "$env_file" ]]; then
  echo "Missing $env_file. See README.md, \"Build configuration\"." >&2
  exit 66
fi

cd "$(dirname "$0")/.."
symbols_dir="build/symbols/$target"
mkdir -p "$symbols_dir"

flutter build "$target" \
  --release \
  --obfuscate \
  --split-debug-info="$symbols_dir" \
  --dart-define-from-file="$env_file"

echo "Symbols for this build: $symbols_dir"
