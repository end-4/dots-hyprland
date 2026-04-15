# function fish_prompt -d "Write out the prompt"
#     # This shows up as USER@HOST /home/user/ >, with the directory colored
#     # $USER and $hostname are set by fish, so you can just use them
#     # instead of using `whoami` and `hostname`
#     printf '%s@%s %s%s%s > ' $USER $hostname \
#         (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
# end
#
if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    # # Use starship
    starship init fish | source
    # if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    #     cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    # end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    alias n touch
    alias code 'cd /run/media/ym/DATA/Code/'
    alias v 'nvim .'
    alias c clear
    alias ns 'npm start'
    alias nd 'npm run dev'
    alias dc 'docker compose'
    alias gst 'git status'
    alias desktop 'cd /run/media/ym/8016C89B16C89416/Users/youngmarco/Desktop/'
    # alias gh copilot
    alias lg lazygit
end
