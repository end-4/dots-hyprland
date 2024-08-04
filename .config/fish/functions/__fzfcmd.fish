function __fzfcmd
    set -q FZF_TMUX; or set FZF_TMUX 0
    set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40%
    if test $FZF_TMUX -eq 1
        echo "fzf-tmux -d$FZF_TMUX_HEIGHT"
    else
        echo "fzf"
    end
end
