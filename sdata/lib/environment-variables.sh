# This is NOT a script for execution, but for loading functions, so NOT need execution permission or shebang.
XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}
XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
BACKUP_DIR=${BACKUP_DIR:-$HOME/backup}


# Note that all color styles contains a STY_RESET before it.
STY_RED='\e[00m\e[31m'
STY_GREEN='\e[00m\e[32m'
STY_YELLOW='\e[00m\e[33m'
STY_BLUE='\e[00m\e[34m'
STY_PURPLE='\e[00m\e[35m'
STY_CYAN='\e[00m\e[36m'

STY_BG_RED='\e[30m\e[41m'
STY_BG_GREEN='\e[30m\e[42m'
STY_BG_YELLOW='\e[30m\e[43m'
STY_BG_BLUE='\e[30m\e[44m'
STY_BG_PURPLE='\e[30m\e[45m'
STY_BG_CYAN='\e[30m\e[46m'

STY_BOLD='\e[1m'
STY_FAINT='\e[2m'
STY_SLANT='\e[3m'
STY_UNDERLINE='\e[4m'
STY_BLINK='\e[5m'
STY_INVERT='\e[7m'
STY_RESET='\e[00m'
