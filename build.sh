#!/bin/bash
set -euo pipefail

docker build \
  -t swampfox/thirdparty/pgformatter:4.4 \
  -t swampfox/thirdparty/pgformatter:latest \
  .
