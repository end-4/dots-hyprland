#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export STATE_DIR
export SCRIPT_DIR
export term_alpha="${term_alpha:-100}" # Set this to < 100 make all your terminals transparent

if [ ! -d "$STATE_DIR"/user/generated ]; then
  mkdir -p "$STATE_DIR"/user/generated
fi
cd "$CONFIG_DIR" || exit

apply_templates() {
  python3 - << 'EOF'
import os, sys

state_dir = os.path.expanduser(os.environ.get('STATE_DIR', '~/.local/state/quickshell'))
script_dir = os.path.expanduser(os.environ.get('SCRIPT_DIR', '~/.config/quickshell/ii/scripts/colors'))
term_alpha = os.environ.get('term_alpha', '100')

scss_path = f"{state_dir}/user/generated/material_colors.scss"
if not os.path.exists(scss_path):
    sys.exit(0)

colors = {}
with open(scss_path, 'r') as f:
    for line in f:
        if ':' in line:
            parts = line.split(':', 1)
            k = parts[0].strip()
            v = parts[1].strip().rstrip(';').lstrip('#')
            colors[k] = v

out_dir = f"{state_dir}/user/generated/terminal"
os.makedirs(out_dir, exist_ok=True)

# 1. Kitty theme
kitty_tpl = f"{script_dir}/terminal/kitty-theme.conf"
if os.path.exists(kitty_tpl):
    with open(kitty_tpl, 'r') as f:
        kitty_content = f.read()
    for k, v in colors.items():
        kitty_content = kitty_content.replace(f"{k} #", v)
    with open(f"{out_dir}/kitty-theme.conf", 'w') as f:
        f.write(kitty_content)

# 2. Sequences txt
seq_tpl = f"{script_dir}/terminal/sequences.txt"
if os.path.exists(seq_tpl):
    with open(seq_tpl, 'r') as f:
        seq_content = f.read()
    for k, v in colors.items():
        seq_content = seq_content.replace(f"{k} #", v)
    seq_content = seq_content.replace("$alpha", term_alpha)
    with open(f"{out_dir}/sequences.txt", 'w') as f:
        f.write(seq_content)
EOF
}

apply_kitty() {
  rm -f "$XDG_CONFIG_HOME/kitty"/*.auto.conf 2>/dev/null || true
  if pgrep -x kitty >/dev/null; then
    kill -SIGUSR1 $(pgrep -x kitty) 2>/dev/null || true
  fi
}

is_editor_pts() {
  local pts="$1"
  local pids
  pids=$(fuser "$pts" 2>/dev/null)
  if [ -z "$pids" ]; then
    pids=$(ps -t "pts/${pts##*/}" -o pid= 2>/dev/null)
  fi
  [ -z "$pids" ] && return 1

  for pid in $pids; do
    if [ -r "/proc/$pid/environ" ]; then
      if tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep -qE '^(VSCODE_|ZCODE_|ELECTRON_RUN_AS_NODE|TERM_PROGRAM=(vscode|kiro|cursor|windsurf|codium|zcode|positron))'; then
        return 0
      fi
    fi

    local cur_pid="$pid"
    for ((i=0; i<4; i++)); do
      [ -z "$cur_pid" ] || [ "$cur_pid" -le 1 ] && break
      local comm cmdline ppid
      comm=$(cat "/proc/$cur_pid/comm" 2>/dev/null || true)
      cmdline=$(cat "/proc/$cur_pid/cmdline" 2>/dev/null | tr '\0' ' ' || true)
      ppid=$(awk '{print $4}' "/proc/$cur_pid/stat" 2>/dev/null || true)

      if echo "$comm $cmdline" | grep -iqE '(code|kiro|zcode|cursor|windsurf|codium|ptyhost|electron)'; then
        if ! echo "$comm" | grep -iqE '(agy|grep)'; then
          return 0
        fi
      fi
      cur_pid="$ppid"
    done
  done
  return 1
}

apply_anyterm() {
  local seq_file="$STATE_DIR/user/generated/terminal/sequences.txt"
  for file in /dev/pts/*; do
    if [[ $file =~ ^/dev/pts/[0-9]+$ ]]; then
      if is_editor_pts "$file"; then
        # Inside editor terminal: restore editor's default theme (reset OSC 110, 111, 112, 104)
        printf '\033]110\033\\\033]111\033\\\033]112\033\\\033]104\033\\' >"$file" 2>/dev/null || true
      elif [ -f "$seq_file" ]; then
        # Standalone terminal: apply OS dynamic color scheme
        cat "$seq_file" >"$file" 2>/dev/null || true
      fi
    fi
  done
}

apply_term() {
  apply_templates
  apply_kitty
  apply_anyterm
}

# Check if terminal theming is enabled in config
CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"
if [ -f "$CONFIG_FILE" ]; then
  enable_terminal=$(jq -r '.appearance.wallpaperTheming.enableTerminal' "$CONFIG_FILE")
  if [ "$enable_terminal" = "true" ]; then
    apply_term
  fi
else
  echo "Config file not found at $CONFIG_FILE. Applying terminal theming by default."
  apply_term
fi
