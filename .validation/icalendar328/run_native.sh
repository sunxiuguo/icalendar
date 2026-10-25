#!/usr/bin/env bash
# Reviewed native-stage runner; not called by metadata-only workflow.
# Usage: bash run_native.sh PHASE ROOT GEMFILE_SHA256 LOCK_SHA256 TZINFO_SHA256 ICALENDAR_SHA256
set -euo pipefail
[ "$#" -eq 6 ] || { echo 'Six explicit arguments required' >&2; exit 2; }
phase=$1
root=$(cd -- "$2" && pwd -P)
gemfile_hash=$3
lock_hash=$4
tzinfo_hash=$5
icalendar_hash=$6
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
case "$phase" in baseline-full|baseline-red|candidate-focused|candidate-full) ;; *) exit 2 ;; esac
for value in "$gemfile_hash" "$lock_hash" "$tzinfo_hash" "$icalendar_hash"; do
  [[ "$value" =~ ^[0-9a-f]{64}$ ]] || { echo 'Reviewed SHA-256 required' >&2; exit 2; }
done
cd -- "$root"
# Each worktree must have its own Gemfile.ci with a local `gemspec` and its own lock.
# Identical reviewed dependency versions are required across red/green worktrees.
[ ! -L Gemfile.ci ] && [ ! -L Gemfile.ci.lock ]
printf '%s  %s\n' "$gemfile_hash" Gemfile.ci "$lock_hash" Gemfile.ci.lock \
  "$tzinfo_hash" lib/icalendar/tzinfo.rb "$icalendar_hash" lib/icalendar.rb | sha256sum --check --strict
unset RUBYOPT RUBYLIB BUNDLE_GEMFILE
export BUNDLE_GEMFILE="$root/Gemfile.ci"
export BUNDLE_FROZEN=true BUNDLE_IGNORE_CONFIG=true BUNDLE_PLUGINS=false
export ICALENDAR_EXPECTED_ROOT="$root"
export ICALENDAR_EXPECTED_TZINFO_SHA256="$tzinfo_hash"
export ICALENDAR_EXPECTED_LIBRARY_SHA256="$icalendar_hash"
export ICALENDAR_EXPECTED_GEMFILE_SHA256="$gemfile_hash"
export ICALENDAR_EXPECTED_LOCK_SHA256="$lock_hash"
guard="$script_dir/verify_native_source.rb"
case "$phase" in
  baseline-red)
    # Remove only this runner's known result. An early exit 1 must not reuse old JSON.
    result="$root/expected-red.json"
    [ ! -L "$result" ] || { echo 'Refusing a symlink result' >&2; exit 2; }
    rm -f -- "$result"
    [ ! -e "$result" ] || { echo 'Stale result removal failed' >&2; exit 2; }
    set +e
    bundle _2.6.9_ exec rspec -I "$root/lib" --require "$guard" \
      spec/tzinfo_future_recurrence_spec.rb --format json --out "$result"
    status=$?
    set -e
    [ "$status" -eq 1 ] || { printf 'Expected RSpec exit 1; got %s\n' "$status" >&2; exit 1; }
    [ -f "$result" ] && [ ! -L "$result" ] && [ -s "$result" ] || {
      echo 'RSpec did not produce a new nonempty JSON result' >&2; exit 1;
    }
    ruby "$script_dir/verify_expected_red.rb" "$result"
    ;;
  candidate-focused)
    bundle _2.6.9_ exec rspec -I "$root/lib" --require "$guard" \
      spec/tzinfo_spec.rb spec/tzinfo_future_recurrence_spec.rb \
      spec/transition_rule_sample_spec.rb spec/timezone_spec.rb spec/roundtrip_spec.rb
    ;;
  baseline-full|candidate-full)
    # RSpec rake task supports SPEC_OPTS; preserve its original suite selection.
    SPEC_OPTS="-I $root/lib --require $guard" bundle _2.6.9_ exec rake spec
    ;;
esac
# Frozen execution must not alter the reviewed Gemfile or dependency lock.
printf '%s  %s\n' "$gemfile_hash" Gemfile.ci "$lock_hash" Gemfile.ci.lock | sha256sum --check --strict
