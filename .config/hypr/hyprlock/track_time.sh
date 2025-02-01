#!/bin/bash

# Check if a media player is active
player_status=$(playerctl status 2>&1)

if [[ "$player_status" == *"No players found"* ]]; then
  exit 1
fi

# Get the current position in seconds
current_position=$(playerctl position)

# Get the total duration in microseconds
total_duration_ns=$(playerctl metadata mpris:length)

# Convert current position into mm:ss format
current_minutes=$(printf "%02d" $((${current_position%.*} / 60)))
current_seconds=$(printf "%02d" $((${current_position%.*} % 60)))
current_time="$current_minutes:$current_seconds"

# Convert microseconds to seconds
total_duration_seconds=$((total_duration_ns / 1000000))

# Convert total seconds into mm:ss format
total_minutes=$(printf "%02d" $(($total_duration_seconds / 60)))
total_seconds=$(printf "%02d" $(($total_duration_seconds % 60)))
total_time="$total_minutes:$total_seconds"

# Display the output in the desired format
echo "$current_time / $total_time"
