#!/usr/bin/env bash
# build-exec.sh

# Rebuild file and run binary when changes occur

cd $(dirname $0)/..
shards build "$1" && exec ./bin/"$1" "${@:2}"
