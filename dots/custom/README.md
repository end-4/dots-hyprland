# Custom Dotfiles Extension

This folder is for **your personal additions** to the dotfiles. It runs at the end of `./setup install`.

## Structure

```
dots/custom/
├── README.md      ← You are here
├── packages.sh    ← Extra packages to install
├── files.sh      ← Extra files to copy
├── commands.sh   ← Extra commands to run
└── misc.sh       ← Miscellaneous custom items
```

## How It Works

During `./setup install`, after all normal installation steps complete, the script
sources `dots/custom/*.sh` and runs your custom functions. You can safely edit the
contents of these files - they will not be overwritten by upstream updates.

## IMPORTANT RULES

1. **DO NOT rename or remove function names** - The script expects specific
   function names. Look at the templates below to see what functions exist.

2. **One entry per line** - When adding packages, files, or commands, add ONE
   per line. Do not stack multiple entries on one line.

3. **Follow the comment pattern** - Entries go AFTER the `#` comment marker.
   The script reads lines that start with `#` and removes the `#` to get the value.

4. **Test your changes** - After editing, run `./setup install` to apply.

5. **Syntax matters** - If your entry has spaces, use quotes. Example:
   ```
   # my program with spaces
   "my program with spaces"
   ```

## File-by-File Guide

---

### packages.sh - Extra Packages

**Purpose:** Install additional packages not included in the main dotfiles.

**Function:** `custom_packages()`
**What it does:** Adds packages to the install list. Supports Arch (pacman), Debian (apt), Fedora (dnf).

**Usage:**
```bash
custom_packages() {
    # firefox
    # vlc
    # thunderbird
}
```

**Notes:**
- Package names are distro-agnostic by default
- If a package has a different name on your distro, the install script will
  attempt to find the correct package manager command

---

### files.sh - Extra Files to Copy

**Purpose:** Copy additional files from your repo to your home/config directories.

**Function:** `custom_files()`
**What it does:** Copies files/dirs in `dots/custom/files/` to your system.

**Usage:**
```bash
# Create a "files" subfolder next to this README:
# dots/custom/files/.config/myapp.conf
# dots/custom/files/.local/share/data

custom_files() {
    # This copies dots/custom/files/* to $HOME/
    local src_dir="dots/custom/files"
    local dest_dir="$HOME"
    rsync_dir "$src_dir" "$dest_dir"

    # Or copy specific files:
    # cp_file "dots/custom/files/.config/app.conf" "$HOME/.config/app.conf"
}
```

**Helper functions available:**
- `cp_file <source> <destination>` - Copy a single file
- `rsync_dir <source_dir> <dest_dir>` - Copy entire directory

---

### commands.sh - Extra Commands to Run

**Purpose:** Run arbitrary shell commands during installation.

**Function:** `custom_commands()`
**What it does:** Executes any shell commands you specify.

**Usage:**
```bash
custom_commands() {
    # Create a directory
    # mkdir -p ~/.local/share/myapp

    # Enable a service
    # systemctl --user enable myservice

    # Set permissions
    # chmod +x ~/.local/bin/myscript

    # Clone a repo
    # git clone https://github.com/user/repo ~/.local/share/repo
}
```

**Notes:**
- Commands run with `bash -c`, so you can use pipes, redirects, etc.
- Be careful - these run as your user, not root (unless you use sudo)

---

### misc.sh - Miscellaneous Items

**Purpose:** Anything that doesn't fit into deps, files, or commands.

**Function:** `custom_misc()`
**What it does:** Runs mixed customizations - create symlinks, edit configs, etc.

**Usage:**
```bash
custom_misc() {
    # Create a symlink to a script in your custom folder
    # ln -sf "$(pwd)/dots/custom/scripts/my-script.sh" "$HOME/.local/bin/my-script"

    # Set environment variables
    # echo 'export MY_VAR="value"' >> "$HOME/.bashrc"

    # Create empty directories with specific permissions
    # mkdir -p ~/.local/share/myapp && chmod 700 ~/.local/share/myapp

    # Register a custom systemd user service placeholder
    # mkdir -p "$HOME/.config/systemd/user/"
}
```

---

## Examples

### Example 1: Install Firefox and VS Code

Edit `deps.sh`:
```bash
custom_packages() {
    # firefox
    # code
}
```

### Example 2: Copy your MPV config

1. Create `dots/custom/files/.config/mpv/mpv.conf`
2. Add your config content
3. Edit `files.sh`:
```bash
custom_files() {
    local src="dots/custom/files"
    local dest="$HOME"
    rsync_dir "$src" "$dest"
}
```

### Example 3: Create symlink and set permissions

Edit `commands.sh`:
```bash
custom_commands() {
    # ln -sf ~/dots/dots/custom/my_script.sh ~/.local/bin/my_script
    # chmod +x ~/dots/custom/my_script.sh
}
```

---

## Troubleshooting

**Q: My changes don't appear after running install.**
A: Make sure you uncommented the lines (removed the leading `#`). Also check for
   syntax errors - missing quotes, unmatched braces, etc.

**Q: The install script fails with an error.**
A: Check the error message. Common issues:
   - Forgot to close a quote
   - Function name doesn't match expected name
   - Path doesn't exist

**Q: How do I skip my custom additions for one install?**
A: You can temporarily rename `dots/custom/` to something else, or set an
   environment variable if supported.

**Q: Can I add my own functions?**
A: Yes, but they won't be called automatically. Only `custom_packages()`,
   `custom_files()`, `custom_commands()`, and `custom_misc()` are called
   by the main script.

---

## Further Help

- Main dotfiles docs: https://ii.clsty.link
- GitHub issues: https://github.com/omsenjalia/dots-hyprland/issues
