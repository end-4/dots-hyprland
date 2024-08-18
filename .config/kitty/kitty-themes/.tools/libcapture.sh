#!/usr/bin/env bash

function capture_linux() {
	local title="$1"
	local output="$2"
	import -window "$title" "$output"
}

function capture_osx() {
	local title="$1"
	local output="$2"
	# get system id of the new created window
	sys_id=$(./windowid.swift "kitty" "$title")
	screencapture -wl"$sys_id" "$output"
}

function capture() {
	if [[ "$OSTYPE" == "linux-gnu" ]]; then
		capture_linux "$@"
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		capture_osx "$@"
	fi
}
