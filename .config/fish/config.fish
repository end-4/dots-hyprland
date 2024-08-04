if status is-interactive
    # Commands to run in interactive sessions can go here
    #	set -U SPACEFISH_PROMPT_ADD_NEWLINE false
    set -U SPACEFISH_EXIT_CODE_SHOW true
    set -U SPACEFISH_EXIT_CODE_SYMBOL
    set -U FZF_LEGACY_KEYBINDINGS 0
    set -U SPACEFISH_TIME_SHOW true

    alias pamcan=pacman
    alias hddd='sudo hdparm -y /dev/sdb /dev/sdd /dev/sde'
    alias hdds='sudo hdparm -C /dev/sdb /dev/sdd /dev/sde'
    alias venv='python -m venv'
    alias venv38='python3.8 -m venv'
    alias activate='source bin/activate.fish'
    alias ls='ls --color=auto'
    alias getpass='pwgen -ysBv'
    alias lsd='lsd -l'
end
#function fish_prompt -d "Write out the prompt"
#    # This shows up as USER@HOST /home/user/ >, with the directory colored
#    # $USER and $hostname are set by fish, so you can just use them
#    # instead of using `whoami` and `hostname`
#    printf '%s@%s %s%s%s > ' $USER $hostname \
#        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
#end
if test -f ~/.cache/ags/user/generated/terminal/sequences.txt
    cat ~/.cache/ags/user/generated/terminal/sequences.txt
end
