function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting

end

starship init fish | source
if test -f ~/.cache/ags/user/generated/terminal/sequences.txt
    cat ~/.cache/ags/user/generated/terminal/sequences.txt
end

alias pamcan=pacman
alias vim=nvim
alias ins='sudo pacman -S'
alias virtualbox='bash -c "QT_STYLE_OVERRIDE=kvantum VirtualBox"'
alias openfile="fzf | xargs -o xdg-open"




# function fish_prompt
#   set_color cyan; echo (pwd)
#   set_color green; echo '> '
# end

fish_add_path /home/deb/.spicetify
set -gx EDITOR nvim
source (/usr/bin/starship init fish --print-full-init | psub)
mcfly init fish | source
set -gx TERMINAL kitty
alias term='kitty'


source /usr/share/cachyos-fish-config/cachyos-config.fish

fastfetch
