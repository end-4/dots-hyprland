#!/usr/bin/env bash

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

_SCRIPT_NAME="$(basename "${BASH_SOURCE[1]:-$0}")"
log_info()    { printf "${BLUE}[%s][INFO]${NC} %s\n"    "$_SCRIPT_NAME" "$*"; }
log_success() { printf "${GREEN}[%s][OK]${NC} %s\n"     "$_SCRIPT_NAME" "$*"; }
log_warning() { printf "${YELLOW}[%s][WARN]${NC} %s\n"  "$_SCRIPT_NAME" "$*"; }
log_error()   { printf "${RED}[%s][ERROR]${NC} %s\n"    "$_SCRIPT_NAME" "$*" >&2; }
