#!/usr/bin/env bash
# Validation stage ONLY, not part of metadata-only workflow.
# Explicit reviewed inputs, never an ambient Gemfile/lock/source selection.
# Usage: run_expected_red.sh ROOT GEMFILE_SHA256 LOCK_SHA256 TZINFO_SHA256 ICALENDAR_SHA256
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
exec bash "$script_dir/run_native.sh" baseline-red "$@"
