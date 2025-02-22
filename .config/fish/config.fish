# Add ~/.local/bin to the PATH if it's not already there
set -U fish_user_paths ~/.local/bin $fish_user_paths

# Initialize Oh My Posh with the specific theme (this should be the first thing to run)
oh-my-posh init fish --config ~/.cache/oh-my-posh/themes/hul10.omp.json | source

# Additional commands for interactive sessions
if status is-interactive
    set fish_greeting
end

# Optional: Include the sequences.txt if needed
if test -f ~/.cache/ags/user/generated/terminal/sequences.txt
    cat ~/.cache/ags/user/generated/terminal/sequences.txt
end

# Alias for pacman
alias pamcan=pacman

fish_add_path /home/patrick/.spicetify
