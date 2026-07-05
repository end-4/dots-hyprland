#!/usr/bin/env bash
# Run a script inside the illogical-impulse virtual environment
# Usage: run-in-venv.sh <script_relpath> [args...]
#   script_relpath: path relative to the scripts/ directory (e.g. images/find_regions.py)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
export GIO_USE_VFS=local
"$SCRIPT_DIR/$@"
EXIT_CODE=$?
deactivate
exit $EXIT_CODE
