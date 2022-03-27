#!/usr/bin/env bash

docker compose up || docker-compose up

_wdio_result="$(cat ./_wdio_result)"
rm "./_wdio_result"

if [[ $_wdio_result == "OK" ]]; then
  exit 0
else
  exit 1
fi
