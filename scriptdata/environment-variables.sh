# This is NOT a script for execution, but for loading functions, so NOT need execution permission or shebang.
XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}
XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
BACKUP_DIR=${BACKUP_DIR:-$HOME/backup}


COLOR_RED='\e[00m\e[31m'
COLOR_GREEN='\e[00m\e[32m'
COLOR_YELLOW='\e[00m\e[33m'
COLOR_BLUE='\e[00m\e[34m'
COLOR_PURPLE='\e[00m\e[35m'
COLOR_CYAN='\e[00m\e[36m'
COLOR_RESET='\e[00m'

STYLE_UNDERLINE='\e[4m'
BG_COLOR_CYAN='\e[30m\e[46m'
BG_COLOR_RED='\e[30m\e[41m'
