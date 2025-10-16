#!/usr/bin/env bash

# Check if GeoClue agent is already running
if pgrep -f 'geoclue-2.0/demos/agent' > /dev/null; then
    echo "GeoClue agent is already running."
    exit 0
fi

# List of known possible GeoClue agent paths
AGENT_PATHS="
/usr/libexec/geoclue-2.0/demos/agent
/usr/lib/geoclue-2.0/demos/agent
"

# Find the first valid agent path
for path in $AGENT_PATHS; do
    if [ -x "$path" ]; then
        echo "Starting GeoClue agent from: $path"
        "$path" & # starts in the background
        exit 0
    fi
done

# If we got here, none of the paths worked
echo "GeoClue agent not found in known paths."
echo "Please install GeoClue or update the script with the correct path."
exit 1
