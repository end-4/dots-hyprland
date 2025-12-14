#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
GIO_USE_VFS=local "$SCRIPT_DIR/thumbgen.py" "$@"
deactivate

