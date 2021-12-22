#!/usr/bin/env bash

set -euo pipefail
ROOT="$(dirname $0)"

SUDO="sudo"

"${ROOT}/download-iso.sh" "css"
CSS_ISO=(css-*.iso)
$SUDO "${ROOT}/rootfs.sh" "${CSS_ISO[0]}"
