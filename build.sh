#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo 'This script should be run as root.'
    exit 1
fi

set -euo pipefail

variant=$1

project_root=$(dirname "$(realpath "$0")")

"$project_root/buildroot.sh" "$variant"
"$project_root/buildiso.sh" "$variant"