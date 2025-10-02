#!/usr/bin/env bash
cd "$(dirname "$0")"
export base="$(pwd)"
source ./scriptdata/environment-variables.sh
source ./scriptdata/functions.sh
source ./scriptdata/package-installers.sh
source ./scriptdata/options.sh

prevent_sudo_or_root
set -e

#####################################################################################
# 0. Before we start
source ./scriptdata/0.install-greeting.sh
#####################################################################################
if [[ "${SKIP_ALLDEPS}" != true ]]; then
  printf "${STY_CYAN}[$0]: 1. Install dependencies\n${STY_RESET}"
  source ./scriptdata/1.install-deps-selector.sh
fi
#####################################################################################
if [[ "${SKIP_ALLSETUPS}" != true ]]; then
  printf "${STY_CYAN}[$0]: 2. Setup for permissions/services etc\n${STY_RESET}"
  source ./scriptdata/2.install-setups-selector.sh
fi
#####################################################################################
if [[ "${SKIP_ALLFILES}" != true ]]; then
  printf "${STY_CYAN}[$0]: 3. Copying config files\n${STY_RESET}"
  source ./scriptdata/3.install-files.sh
fi
