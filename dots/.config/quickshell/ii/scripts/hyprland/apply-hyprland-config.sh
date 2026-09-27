#!/usr/bin/env bash
# Script to apply Hyprland configuration from illogical-impulse config.json

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
get_config_file() {
    local current_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
    if [[ "$current_mode" == "prefer-dark" ]]; then
        echo "$XDG_CONFIG_HOME/illogical-impulse/config.json"
    else
        echo "$XDG_CONFIG_HOME/illogical-impulse/config-light.json"
    fi
}
SHELL_CONFIG_FILE="$(get_config_file)"
HYPR_CONFIG_DIR="$XDG_CONFIG_HOME/hypr"
HYPRLAND_GENERAL_CONF="$HYPR_CONFIG_DIR/hyprland/general.conf"
CUSTOM_RULES_CONF="$HYPR_CONFIG_DIR/custom/rules.conf"
KITTY_CONF="$XDG_CONFIG_HOME/kitty/kitty.conf"

# Check if config file exists
if [ ! -f "$SHELL_CONFIG_FILE" ]; then
    echo "Config file not found: $SHELL_CONFIG_FILE"
    notify-send "Hyprland Settings" "Config file not found" -a "illogical-impulse" -u critical 2>/dev/null || true
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is required but not installed"
    notify-send "Hyprland Settings" "jq is required but not installed" -a "illogical-impulse" -u critical 2>/dev/null || true
    exit 1
fi

# Create config directories if they don't exist
mkdir -p "$HYPR_CONFIG_DIR/hyprland"
mkdir -p "$HYPR_CONFIG_DIR/custom"
mkdir -p "$(dirname "$KITTY_CONF")"

# Get config value
get_config_value() {
    local path="$1"
    local value=$(jq -r "$path" "$SHELL_CONFIG_FILE" 2>/dev/null)
    echo "$value"
}

# Apply general.conf settings
apply_general_conf() {
    echo "Applying general.conf settings"

    # Backup original file
    if [ -f "$HYPRLAND_GENERAL_CONF" ]; then
        cp "$HYPRLAND_GENERAL_CONF" "$HYPRLAND_GENERAL_CONF.bak"
    fi

    # Get values from config
    local gaps_in=$(get_config_value ".hyprland.general.gaps.gapsIn")
    local gaps_out=$(get_config_value ".hyprland.general.gaps.gapsOut")
    local gaps_workspaces=$(get_config_value ".hyprland.general.gaps.gapsWorkspaces")
    local border_size=$(get_config_value ".hyprland.general.border.borderSize")
    local col_active=$(get_config_value ".hyprland.general.border.colActiveBorder")
    local col_inactive=$(get_config_value ".hyprland.general.border.colInactiveBorder")
    local rounding=$(get_config_value ".hyprland.decoration.rounding")
    local blur_enabled=$(get_config_value ".hyprland.decoration.blur.enabled")
    local blur_size=$(get_config_value ".hyprland.decoration.blur.size")
    local blur_passes=$(get_config_value ".hyprland.decoration.blur.passes")

    # Read the file and update values
    if [ -f "$HYPRLAND_GENERAL_CONF" ]; then
        # Update gaps (within general block)
        sed -i '/^general[[:space:]]*{/,/^}/ {
            s/^\([[:space:]]*gaps_in[[:space:]]*=[[:space:]]*\).*/\1'"$gaps_in"'/
            s/^\([[:space:]]*gaps_out[[:space:]]*=[[:space:]]*\).*/\1'"$gaps_out"'/
            s/^\([[:space:]]*gaps_workspaces[[:space:]]*=[[:space:]]*\).*/\1'"$gaps_workspaces"'/
        }' "$HYPRLAND_GENERAL_CONF"

        # Update border (within general block)
        sed -i '/^general[[:space:]]*{/,/^}/ {
            s/^\([[:space:]]*border_size[[:space:]]*=[[:space:]]*\).*/\1'"$border_size"'/
            s|^\([[:space:]]*col\.active_border[[:space:]]*=[[:space:]]*\).*|\1'"$col_active"'|
            s|^\([[:space:]]*col\.inactive_border[[:space:]]*=[[:space:]]*\).*|\1'"$col_inactive"'|
        }' "$HYPRLAND_GENERAL_CONF"

        # Update decoration rounding
        sed -i '/^decoration[[:space:]]*{/,/^}/ {
            s/^\([[:space:]]*rounding[[:space:]]*=[[:space:]]*\).*/\1'"$rounding"'/
        }' "$HYPRLAND_GENERAL_CONF"

        # Update blur settings (within decoration { blur { } } block)
        sed -i '/^decoration[[:space:]]*{/,/^}/ {
            /blur[[:space:]]*{/,/^[[:space:]]*}/ {
                s/^\([[:space:]]*enabled[[:space:]]*=[[:space:]]*\).*/\1'"$blur_enabled"'/
                s/^\([[:space:]]*size[[:space:]]*=[[:space:]]*\).*/\1'"$blur_size"'/
                s/^\([[:space:]]*passes[[:space:]]*=[[:space:]]*\).*/\1'"$blur_passes"'/
            }
        }' "$HYPRLAND_GENERAL_CONF"
    fi
}

# Apply window rules - using opacity variables
apply_window_rules() {
    echo "Applying window opacity variables"

    # Backup original file
    if [ -f "$CUSTOM_RULES_CONF" ]; then
        cp "$CUSTOM_RULES_CONF" "$CUSTOM_RULES_CONF.bak"
    fi

    # Get opacity values from config
    local opacity_active=$(get_config_value ".hyprland.windowRules.opacityActive")
    local opacity_inactive=$(get_config_value ".hyprland.windowRules.opacityInactive")

    if [ -f "$CUSTOM_RULES_CONF" ]; then
        # Create or update the opacity variables section at the top of the file
        # First, remove old opacity variables section if it exists
        sed -i '/# Opacity Variables - Managed by illogical-impulse/,/# End Opacity Variables/d' "$CUSTOM_RULES_CONF"

        # Create temp file with opacity variables at the top
        local temp_file="${CUSTOM_RULES_CONF}.tmp"
        {
            echo "# Opacity Variables - Managed by illogical-impulse"
            echo "# Use these variables in your window rules:"
            echo "# windowrulev2 = opacity \$OPACITY_ACTIVE override \$OPACITY_INACTIVE override, class:^(yourapp)\$"
            echo "\$OPACITY_ACTIVE = $opacity_active"
            echo "\$OPACITY_INACTIVE = $opacity_inactive"
            echo "# End Opacity Variables"
            cat "$CUSTOM_RULES_CONF"
        } > "$temp_file"

        mv "$temp_file" "$CUSTOM_RULES_CONF"
    fi
}

# Apply kitty.conf settings
apply_kitty_conf() {
    echo "Applying kitty.conf settings"

    # Backup original file
    if [ -f "$KITTY_CONF" ]; then
        cp "$KITTY_CONF" "$KITTY_CONF.bak"
    fi

    # Get value from config
    local bg_opacity=$(get_config_value ".hyprland.terminal.kittyBackgroundOpacity")

    if [ -f "$KITTY_CONF" ]; then
        # Update background_opacity (POSIX-compatible pattern)
        sed -i "s/^[[:space:]]*background_opacity[[:space:]]\+.*/background_opacity $bg_opacity/" "$KITTY_CONF"
    fi
}

# Reload Hyprland configuration
reload_hyprland() {
    echo "Reloading Hyprland configuration..."
    hyprctl reload 2>/dev/null || true
}

# Main execution
main() {
    echo "Applying Hyprland configuration..."

    apply_general_conf
    apply_window_rules
    apply_kitty_conf
    reload_hyprland

    echo "Hyprland configuration applied successfully!"

    # Send notification
    notify-send "Hyprland Settings" "Configuration applied successfully" -a "illogical-impulse" -i "preferences-system" 2>/dev/null || true
}

main "$@"
