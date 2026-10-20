#!/usr/bin/env bash
# Runs every tests/test_*.sh; exits non-zero if any fail.
cd "$(dirname "$0")" || exit 1
rc=0
for t in tests/test_*.sh; do echo "# $t"; bash "$t" || rc=1; done
exit $rc
