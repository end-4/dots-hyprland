# This script is meant to be sourced.
# It's not for directly running.

# TODO: https://github.com/end-4/dots-hyprland/issues/2137

printf "${STY_CYAN}[$0]: 3. Copying config files (experimental YAML-based)${STY_RST}\n"

# Configuration file
CONFIG_FILE="sdata/subcmd-install/3.files.yaml"

# =============================================================================
# ORIGINAL FUNCTIONS
# =============================================================================

function warning_rsync_delete(){
  printf "${STY_YELLOW}"
  printf "The command below uses --delete for rsync which overwrites the destination folder.\n"
  printf "${STY_RST}"
}

function warning_rsync_normal(){
  printf "${STY_YELLOW}"
  printf "The command below uses rsync which overwrites the destination.\n"
  printf "${STY_RST}"
}

function backup_configs(){
  backup_clashing_targets dots/.config $XDG_CONFIG_HOME "${BACKUP_DIR}/.config"
  backup_clashing_targets dots/.local/share $XDG_DATA_HOME "${BACKUP_DIR}/.local/share"
  printf "${STY_BLUE}Backup into \"${BACKUP_DIR}\" finished.${STY_RST}\n"
}

function ask_backup_configs(){
  showfun backup_clashing_targets
  printf "${STY_RED}"
  printf "Would you like to backup clashing dirs/files under \"$XDG_CONFIG_HOME\" and \"$XDG_DATA_HOME\" to \"$BACKUP_DIR\"?"
  printf "${STY_RST}"
  while true;do
    echo "  y = Yes, backup"
    echo "  n/s = No, skip to next"
    local p; read -p "====> " p
    case $p in
      [yY]) echo -e "${STY_BLUE}OK, doing backup...${STY_RST}" ;local backup=true;break ;;
      [nNsS]) echo -e "${STY_BLUE}Alright, skipping...${STY_RST}" ;local backup=false;break ;;
      *) echo -e "${STY_RED}Please enter [y/n].${STY_RST}";;
     esac
  done
  if $backup;then backup_configs;fi
}
function auto_backup_configs(){
  # Backup when $BACKUP_DIR does not exist
  if [[ ! -d "$BACKUP_DIR" ]]; then backup_configs;fi
}

#####################################################################################
showfun auto_get_git_submodule
v auto_get_git_submodule

# In case some dirs does not exists
v mkdir -p $XDG_BIN_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME $XDG_DATA_HOME/icons

if [[ ! "${SKIP_BACKUP}" == true ]]; then
  case $ask in
    false) auto_backup_configs ;;
    *) ask_backup_configs ;;
  esac
fi

# Run user preference wizard
case $ask in
  false) sleep 0 ;;
  *) wizard_update_preferences ;;
esac

# Read patterns from YAML file
readarray patterns < <(yq -o=j -I=0 '.patterns[]' "$CONFIG_FILE")

# Process each pattern
for pattern in "${patterns[@]}"; do
    from=$(echo "$pattern" | yq '.from' - | envsubst)
    to=$(echo "$pattern" | yq '.to' - | envsubst)
    mode=$(echo "$pattern" | yq '.mode' - | envsubst)
    condition=$(echo "$pattern" | yq '.condition // "true"')
    
    # Handle fontconfig fontset override
    # If II_FONTSET_NAME is set and this is the fontconfig pattern, use the fontset instead
    if [[ "$from" == "dots/.config/fontconfig" ]] && [[ -n "${II_FONTSET_NAME:-}" ]]; then
        from="dots-extra/fontsets/${II_FONTSET_NAME}"
        echo "Using fontset \"${II_FONTSET_NAME}\" for fontconfig"
    fi
    
    # Check if pattern should be processed
    if ! should_process_pattern "$pattern"; then
        # Format condition message nicely
        if [[ "$condition" != "true" ]]; then
            cond_type=$(echo "$condition" | yq -r '.type // ""')
            cond_value=$(echo "$condition" | yq -r '.value // ""')
            if [[ -n "$cond_type" && -n "$cond_value" ]]; then
                echo "Skipping $from -> $to (condition not met: $cond_type == '$cond_value')"
            else
                echo "Skipping $from -> $to (condition not met)"
            fi
        else
            echo "Skipping $from -> $to (condition not met)"
        fi
        continue
    fi
    
    echo "Processing: $from -> $to (mode: $mode)"
    
    # Build exclude arguments for rsync
    excludes=()
    if echo "$pattern" | yq -e '.excludes' >/dev/null 2>&1; then
        while IFS= read -r exclude; do
            excludes+=(--exclude "$exclude")
        done < <(echo "$pattern" | yq -r '.excludes[]')
    fi
    
    # Check if source exists
    if [[ ! -e "$from" ]]; then
        echo "Warning: Source does not exist: $from (skipping)"
        continue
    fi
    
    # Ensure destination directory exists for files
    if [[ -f "$from" ]]; then
        v mkdir -p "$(dirname "$to")"
    fi
    
    # Execute based on mode
    case $mode in
        "sync")
            if [[ -d "$from" ]]; then
                warning_rsync_delete
                v rsync -av --delete "${excludes[@]}" "$from/" "$to/"
            else
                warning_rsync_normal
                # For files, don't use trailing slash and don't use --delete
                v rsync -av "${excludes[@]}" "$from" "$to"
            fi
            ;;
        "soft")
            warning_rsync_normal
            if [[ -d "$from" ]]; then
                v rsync -av "${excludes[@]}" "$from/" "$to/"
            else
                # For files, don't use trailing slash
                v rsync -av "${excludes[@]}" "$from" "$to"
            fi
            ;;
        "hard")
            v cp -r "$from" "$to"
            ;;
        "hard-backup")
            if [[ -e "$to" ]]; then
                if files_are_same "$from" "$to"; then
                    echo "Files are identical, skipping backup"
                else
                    backup_number=$(get_next_backup_number "$to")
                    v mv "$to" "$to.old.$backup_number"
                    v cp -r "$from" "$to"
                fi
            else
                v cp -r "$from" "$to"
            fi
            ;;
        "soft-backup")
            if [[ -e "$to" ]]; then
                if files_are_same "$from" "$to"; then
                    echo "Files are identical, skipping backup"
                else
                    v cp -r "$from" "$to.new"
                fi
            else
                v cp -r "$from" "$to"
            fi
            ;;
        "skip")
            echo "Skipping $from"
            ;;
        "skip-if-exists")
            if [[ -e "$to" ]]; then
                echo "Skipping $from (destination exists)"
            else
                v cp -r "$from" "$to"
            fi
            ;;
        *)
            echo "Unknown mode: $mode"
            ;;
    esac
done

# Prevent hyprland from not fully loaded
sleep 1
try hyprctl reload

# Rest of original script logic...
# (Keep the existing warning messages and file checks)

warn_files=()
warn_files_tests=()
warn_files_tests+=(/usr/local/lib/{GUtils-1.0.typelib,Gvc-1.0.typelib,libgutils.so,libgvc.so})
warn_files_tests+=(/usr/local/share/fonts/TTF/Rubik{,-Italic}'[wght]'.ttf)
warn_files_tests+=(/usr/local/share/licenses/ttf-rubik)
warn_files_tests+=(/usr/local/share/fonts/TTF/Gabarito-{Black,Bold,ExtraBold,Medium,Regular,SemiBold}.ttf)
warn_files_tests+=(/usr/local/share/licenses/ttf-gabarito)
warn_files_tests+=(/usr/local/share/icons/OneUI{,-dark,-light})
warn_files_tests+=(/usr/local/share/icons/Bibata-Modern-Classic)
warn_files_tests+=(/usr/local/bin/{LaTeX,res})
for i in ${warn_files_tests[@]}; do
  echo $i
  test -f $i && warn_files+=($i)
  test -d $i && warn_files+=($i)
done

#####################################################################################
# TODO: output the logs below to a temp file and cat that file, also show the path of the file so users will be able to read it again.
printf "\n"
printf "\n"
printf "\n"
printf "${STY_CYAN}[$0]: Finished${STY_RESET}\n"
printf "\n"
printf "${STY_CYAN}When starting Hyprland from your display manager (login screen) ${STY_RED} DO NOT SELECT UWSM ${STY_RESET}\n"
printf "\n"
printf "${STY_CYAN}If you are already running Hyprland,${STY_RESET}\n"
printf "${STY_CYAN}Press ${STY_BG_CYAN} Ctrl+Super+T ${STY_BG_CYAN} to select a wallpaper${STY_RESET}\n"
printf "${STY_CYAN}Press ${STY_BG_CYAN} Super+/ ${STY_CYAN} for a list of keybinds${STY_RESET}\n"
printf "\n"
printf "${STY_CYAN}For suggestions/hints after installation:${STY_RESET}\n"
printf "${STY_CYAN}${STY_UNDERLINE} https://ii.clsty.link/en/ii-qs/01setup/#post-installation ${STY_RESET}\n"
printf "\n"

if [[ -z "${ILLOGICAL_IMPULSE_VIRTUAL_ENV}" ]]; then
  printf "\n${STY_RED}[$0]: \!! Important \!! : Please ensure environment variable ${STY_RESET} \$ILLOGICAL_IMPULSE_VIRTUAL_ENV ${STY_RED} is set to proper value (by default \"~/.local/state/quickshell/.venv\"), or Quickshell config will not work. We have already provided this configuration in ~/.config/hypr/hyprland/env.conf, but you need to ensure it is included in hyprland.conf, and also a restart is needed for applying it.${STY_RESET}\n"
fi

if [[ ! -z "${warn_files[@]}" ]]; then
  printf "\n${STY_RED}[$0]: \!! Important \!! : Please delete ${STY_RESET} ${warn_files[*]} ${STY_RED} manually as soon as possible, since we\'re now using AUR package or local PKGBUILD to install them for Arch(based) Linux distros, and they'll take precedence over our installation, or at least take up more space.${STY_RESET}\n"
fi
