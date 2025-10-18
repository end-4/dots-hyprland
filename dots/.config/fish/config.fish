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
    #if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    #    cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    #end

    # Fastfetch
    fastfetch

    # Aliases
    alias pamcan pacman
    alias ls 'eza --icons'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias q 'qs -c ii'
    
end

function update
  if test (count $argv) -eq 0
    update flake && update nixos
  else if test "$argv[1]" = "nixos"
    sudo nixos-rebuild switch --flake ~/NixOS\#mou
  else if test "$argv[1]" = "home"
    home-manager switch --flake ~/NixOS\#mou@mou
  else if test "$argv[1]" = "flake"
    nix flake update --flake ~/NixOS
  end
end
