#!/usr/bin/env bash
set -euo pipefail
archive="${1:-deeplearning-legacy-cu113.tar}"
if [[ ! -f "$archive" || ! -f "$archive.sha256" ]]; then
  echo "Missing $archive or $archive.sha256" >&2
  exit 1
fi
(
  cd "$(dirname "$archive")"
  sha256sum -c "$(basename "$archive").sha256"
)
docker load -i "$archive"
docker image inspect deeplearning-legacy:cu113 >/dev/null
echo "Image loaded. GPU test:"
echo "docker run --rm --gpus all deeplearning-legacy:cu113 python3.8 /opt/verify_env.py"
