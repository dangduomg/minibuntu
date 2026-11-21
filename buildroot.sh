#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo 'This script should be run as root.'
    exit 1
fi

set -euo pipefail

variant=$1

project_root=$(dirname "$(realpath "$0")")
src_root=$project_root/src
src_dir=$src_root/$variant
build_root=$project_root/build
build_dir=$build_root/$variant
os_root=$build_dir/root

source "$src_dir/build.sh"