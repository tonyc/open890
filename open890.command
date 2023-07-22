#!/usr/bin/env bash

cd "$(dirname "$BASH_SOURCE")" || {
  echo "Unable to determine script directory" >&2
  exit 1
}

bin/open890 start
