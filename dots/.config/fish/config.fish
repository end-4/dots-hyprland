# Check if running inside an editor's integrated terminal (VSCode, Kiro, ZCode, Cursor, Windsurf, etc.)
set -l is_editor_term 0
if test -n "$VSCODE_INJECTION" -o -n "$VSCODE_PID" -o -n "$ZCODE_PID" -o -n "$ELECTRON_RUN_AS_NODE"
    set is_editor_term 1
else if string match -q -r '^(vscode|kiro|cursor|windsurf|codium|zcode|positron)' "$TERM_PROGRAM"
    set is_editor_term 1
end

if test $is_editor_term -eq 1
    # Inside editor terminal: ensure colors follow the editor's theme, not the OS theme
    set -e COLORFGBG
    set -e GLAMOUR_STYLE
    if status is-interactive
        # Reset any inherited OSC color overrides to editor's default theme
        printf '\033]110\033\\\033]111\033\\\033]112\033\\\033]104\033\\'
    end
else
    # Standalone terminal (Kitty, Foot, etc.): apply dynamic OS terminal mode
    if test -f ~/.local/state/quickshell/user/generated/terminal/colorfgbg.fish
        source ~/.local/state/quickshell/user/generated/terminal/colorfgbg.fish
    end
end

# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting


    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
    end
    
    # Terminal escape sequences for live colors (only for standalone terminals)
    if test $is_editor_term -eq 0
        if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
            cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        end
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    if test "$TERM" != "linux"
        alias ls 'eza --icons=auto'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
end
