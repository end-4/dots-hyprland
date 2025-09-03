function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    # Use starship
    starship init fish | source
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

starship init fish | source
if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
end

alias pamcan=pamcan
alias php="mise exec -- php"
alias yarn="mise exec -- yarn"
alias node="mise exec -- node"
alias pipx="mise exec -- pipx"
alias npm="mise exec -- npm"
alias composer="mise exec -- composer"
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
alias pamcan pacman
alias ls 'eza --icons'
alias clear "printf '\033[2J\033[3J\033[1;1H'"
alias q 'qs -c ii'


# function fish_prompt
#   set_color cyan; echo (pwd)
#   set_color green; echo '> '
# end
