#!/usr/bin/env bash


opal -c -q opal-browser -p native -p promise -p opal-browser -p browser/setup/full -s sorbet -s sorbet-runtime -e '#' -E > ./fragments/vendor/runtime.js
