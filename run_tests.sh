#!/usr/bin/env bash
# Runs every tests/test_*.sh and exits non-zero if any of them fail.

cd "$(dirname "$0")" || exit 1

status=0
for test in tests/test_*.sh; do
  echo "# $test"
  bash "$test" || status=1
done
exit $status
