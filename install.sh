#!/usr/bin/env bash
cd "$(dirname "$0")"
export base="$(pwd)"
source ./scriptdata/environment-variables.sh
source ./scriptdata/functions.sh
source ./scriptdata/installers.sh
source ./scriptdata/options.sh

prevent_sudo_or_root
set -e

#####################################################################################
# 0. Before we start
source ./scriptdata/install-greeting.sh
#####################################################################################
if [[ "${SKIP_ALLDEPS}" != true ]]; then
  printf "${COLOR_CYAN}[$0]: 1. Install dependencies\n${COLOR_RESET}"
  source ./scriptdata/install-deps.sh
fi
#####################################################################################
if [[ "${SKIP_ALLSETUPS}" != true ]]; then
  printf "${COLOR_CYAN}[$0]: 2. Setup for user groups/services etc\n${COLOR_RESET}"
  source ./scriptdata/install-setups.sh
fi
#####################################################################################
if [[ "${SKIP_ALLFILES}" != true ]]; then
  printf "${COLOR_CYAN}[$0]: 3. Copying + Configuring\n${COLOR_RESET}"
  source ./scriptdata/install-files.sh
fi
