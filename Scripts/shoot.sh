#!/bin/zsh
# Usage: Scripts/shoot.sh <udid> <out.png> [launch args...]
# Launches Mr Tipster with the given arguments and saves a screenshot.
set -e
udid=$1; out=$2; shift 2
xcrun simctl launch --terminate-running-process "$udid" com.marybm.mrtipster "$@" >/dev/null
sleep ${SHOOT_DELAY:-3}
xcrun simctl io "$udid" screenshot "$out" >/dev/null 2>&1
