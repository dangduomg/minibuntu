#!/bin/bash

set -euo pipefail

setup_root=$(dirname "$(realpath "$0")")

setup_phases=$(find "$setup_root" -mindepth 1 -maxdepth 1 -type d | sort -n)

for phase in $setup_phases; do
    echo "Running setup phase: $phase"
    bash "$phase/setup.sh"
done