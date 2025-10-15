#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
"$SCRIPT_DIR/least_busy_region.py" "$@"
deactivate
