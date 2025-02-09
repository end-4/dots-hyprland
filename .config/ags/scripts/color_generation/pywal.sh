#!/usr/bin/env bash
# A wrapper for pywal inside the virtual env
source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
#wal "$@"
wal $*
deactivate
