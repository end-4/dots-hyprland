#!/usr/bin/env bash

theme=$1

jq  ".colors | to_entries | map(select(.key | match(\"terminal.*\"))) | map({(.key | gsub(\"\\\\.(?<a>.)\"; .a | ascii_upcase) | ltrimstr(\"terminal\") | sub(\"(?<a>.)\"; .a | ascii_downcase)):.value}) | add" < "$theme" > "terminal/${theme%.*}.json"
