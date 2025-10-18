#!/usr/bin/env bash
cd "$(dirname "$0")"
# Use REPO_ROOT instead of base - when scripts are sourced they do not need export to inherit vars
REPO_ROOT="$(pwd)"
source ./sdata/lib/environment-variables.sh
source ./sdata/lib/functions.sh
source ./sdata/lib/package-installers.sh
source ./sdata/lib/options.sh

prevent_sudo_or_root
set -e

#####################################################################################
# For subcommands
case ${SCRIPT_SUBCOMMAND} in
  exp-uninstall)
    source ./sdata/step/exp-uninstall.sh
    exit
    ;;
  exp-update)
    source ./sdata/step/exp-update.sh
    exit
    ;;
esac
#####################################################################################
# 0. Before we start
if [[ "${SKIP_ALLGREETING}" != true ]]; then
  source ./sdata/step/0.install-greeting.sh
fi
#####################################################################################
if [[ "${SKIP_ALLDEPS}" != true ]]; then
  printf "${STY_CYAN}[$0]: 1. Install dependencies\n${STY_RST}"
  source ./sdata/step/1.install-deps-selector.sh
fi
#####################################################################################
if [[ "${SKIP_ALLSETUPS}" != true ]]; then
  printf "${STY_CYAN}[$0]: 2. Setup for permissions/services etc\n${STY_RST}"
  source ./sdata/step/2.install-setups-selector.sh
fi
#####################################################################################
if [[ "${SKIP_ALLFILES}" != true ]]; then
  printf "${STY_CYAN}[$0]: 3. Copying config files\n${STY_RST}"
  if [[ "${EXPERIMENTAL_FILES_SCRIPT}" == true ]]; then
    source ./sdata/step/3.install-files.experimental.sh
  else
    source ./sdata/step/3.install-files.sh
  fi
fi
