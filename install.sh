#!/usr/bin/env bash
cd "$(dirname "$0")"
export base="$(pwd)"
source ./scriptdata/environment-variables
source ./scriptdata/functions
source ./scriptdata/installers
source ./scriptdata/options

prevent_sudo_or_root
set -e

#####################################################################################
# 0. Before we start
source ./scriptdata/install-greeting ;;
#####################################################################################
printf "\e[36m[$0]: 1. Install dependencies\n\e[0m"
# TODO: if `--via-nix` is specified, source `install-deps-nix` instead.
source ./scriptdata/install-deps-arch
#####################################################################################
printf "\e[36m[$0]: 2. Setup for user groups/services etc\n\e[0m"
source ./scriptdata/install-setups
#####################################################################################
printf "\e[36m[$0]: 3. Copying + Configuring\e[0m\n"
source ./scriptdata/install-files
