#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"
MATUGEN_DIR="$XDG_CONFIG_HOME/matugen"
terminalscheme="$SCRIPT_DIR/terminal/scheme-base.json"

# Prevent concurrent execution collisions
LOCKFILE="${XDG_RUNTIME_DIR:-/tmp}/switchwall.lock"
exec 200>"$LOCKFILE"
if ! flock -n 200; then
    echo "[switchwall.sh] Another instance is already running. Exiting." >&2
    exit 0
fi

handle_kde_material_you_colors() {
    # Check if Qt app theming is enabled in config
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        enable_qt_apps=$(jq -r '.appearance.wallpaperTheming.enableQtApps' "$SHELL_CONFIG_FILE")
        if [ "$enable_qt_apps" == "false" ]; then
            return
        fi
    fi

    # Map $type_flag to allowed scheme variants for kde-material-you-colors-wrapper.sh
    local kde_scheme_variant=""
    case "$type_flag" in
        scheme-content|scheme-expressive|scheme-fidelity|scheme-fruit-salad|scheme-monochrome|scheme-neutral|scheme-rainbow|scheme-tonal-spot)
            kde_scheme_variant="$type_flag"
            ;;
        *)
            kde_scheme_variant="scheme-tonal-spot" # default
            ;;
    esac
    "$XDG_CONFIG_HOME"/matugen/templates/kde/kde-material-you-colors-wrapper.sh --scheme-variant "$kde_scheme_variant"
}

sync_ini_setting() {
    local file="$1"
    local section="$2"
    local key="$3"
    local value="$4"

    mkdir -p "$(dirname "$file")"
    if [ ! -f "$file" ]; then
        printf "[%s]\n%s=%s\n" "$section" "$key" "$value" > "$file"
        return
    fi

    if grep -q -E "^${key}=" "$file"; then
        sed -i -E "s/^(${key}=).*/\1${value}/" "$file"
    elif grep -q -E "^\[${section}\]" "$file"; then
        sed -i -E "/^\[${section}\]/a ${key}=${value}" "$file"
    else
        printf "\n[%s]\n%s=%s\n" "$section" "$key" "$value" >> "$file"
    fi
}

pre_process() {
    local mode_flag="$1"
    local gtk_theme=""
    local color_scheme=""
    local prefer_dark="0"
    local colorfgbg=""
    local glamour_style=""

    if [[ "$mode_flag" == "dark" ]]; then
        color_scheme='prefer-dark'
        gtk_theme='adw-gtk3-dark'
        prefer_dark="1"
        colorfgbg="15;0"
        glamour_style="dark"
    else
        color_scheme='prefer-light'
        gtk_theme='adw-gtk3'
        prefer_dark="0"
        colorfgbg="0;15"
        glamour_style="light"
    fi

    # 1. Set GNOME / GTK desktop interface in gsettings and dconf
    gsettings set org.gnome.desktop.interface color-scheme "$color_scheme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
    dconf write /org/gnome/desktop/interface/color-scheme "'$color_scheme'" 2>/dev/null || true
    dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk_theme'" 2>/dev/null || true

    # Export terminal environment variables for Wayland/Hyprland session
    hyprctl setenv COLORFGBG "$colorfgbg" 2>/dev/null || true
    hyprctl setenv GLAMOUR_STYLE "$glamour_style" 2>/dev/null || true

    # Save to generated terminal env files for shells (fish, bash, etc.)
    mkdir -p "$STATE_DIR/user/generated/terminal"
    echo "set -gx COLORFGBG \"$colorfgbg\"" > "$STATE_DIR/user/generated/terminal/colorfgbg.fish"
    echo "set -gx GLAMOUR_STYLE \"$glamour_style\"" >> "$STATE_DIR/user/generated/terminal/colorfgbg.fish"
    echo "export COLORFGBG=\"$colorfgbg\"" > "$STATE_DIR/user/generated/terminal/colorfgbg.sh"
    echo "export GLAMOUR_STYLE=\"$glamour_style\"" >> "$STATE_DIR/user/generated/terminal/colorfgbg.sh"

    # 2. Update GTK-3.0 settings.ini
    sync_ini_setting "$XDG_CONFIG_HOME/gtk-3.0/settings.ini" "Settings" "gtk-theme-name" "$gtk_theme"
    sync_ini_setting "$XDG_CONFIG_HOME/gtk-3.0/settings.ini" "Settings" "gtk-application-prefer-dark-theme" "$prefer_dark"

    # 3. Update GTK-4.0 settings.ini
    sync_ini_setting "$XDG_CONFIG_HOME/gtk-4.0/settings.ini" "Settings" "gtk-theme-name" "$gtk_theme"
    sync_ini_setting "$XDG_CONFIG_HOME/gtk-4.0/settings.ini" "Settings" "gtk-application-prefer-dark-theme" "$prefer_dark"

    # 4. Update xsettingsd configuration
    mkdir -p "$XDG_CONFIG_HOME/xsettingsd"
    if [ -f "$XDG_CONFIG_HOME/xsettingsd/xsettingsd.conf" ]; then
        sed -i -E "s/^(Net\/ThemeName\s+).*/\1\"$gtk_theme\"/" "$XDG_CONFIG_HOME/xsettingsd/xsettingsd.conf"
        killall -HUP xsettingsd 2>/dev/null || true
    fi

    if [ ! -d "$CACHE_DIR"/user/generated ]; then
        mkdir -p "$CACHE_DIR"/user/generated
    fi
}

post_process() {
    local screen_width="$1"
    local screen_height="$2"
    local wallpaper_path="$3"

    handle_kde_material_you_colors &
    "$SCRIPT_DIR/code/material-code-set-color.sh" &
}

check_and_prompt_upscale() {
    local img="$1"
    min_width_desired="$(hyprctl monitors -j | jq '([.[].width] | max)' | xargs)" # max monitor width
    min_height_desired="$(hyprctl monitors -j | jq '([.[].height] | max)' | xargs)" # max monitor height

    if command -v identify &>/dev/null && [ -f "$img" ]; then
        local img_width img_height
        if is_video "$img"; then # Not check resolution for videos, just let em pass
            img_width=$min_width_desired
            img_height=$min_height_desired
        else
            img_width=$(identify -format "%w" "$img" 2>/dev/null)
            img_height=$(identify -format "%h" "$img" 2>/dev/null)
        fi
        if [[ "$img_width" -lt "$min_width_desired" || "$img_height" -lt "$min_height_desired" ]]; then
            action=$(notify-send "Upscale?" \
                "Image resolution (${img_width}x${img_height}) is lower than screen resolution (${min_width_desired}x${min_height_desired})" \
                -A "open_upscayl=Open Upscayl"\
                -a "Wallpaper switcher")
            if [[ "$action" == "open_upscayl" ]]; then
                if command -v upscayl &>/dev/null; then
                    nohup upscayl > /dev/null 2>&1 &
                else
                    action2=$(notify-send \
                        -a "Wallpaper switcher" \
                        -c "im.error" \
                        -A "install_upscayl=Install Upscayl (Arch)" \
                        "Install Upscayl?" \
                        "yay -S upscayl-bin")
                    if [[ "$action2" == "install_upscayl" ]]; then
                        kitty -1 yay -S upscayl-bin
                        if command -v upscayl &>/dev/null; then
                            nohup upscayl > /dev/null 2>&1 &
                        fi
                    fi
                fi
            fi
        fi
    fi
}

CUSTOM_DIR="$XDG_CONFIG_HOME/hypr/custom"
RESTORE_SCRIPT_DIR="$CUSTOM_DIR/scripts"
RESTORE_SCRIPT="$RESTORE_SCRIPT_DIR/__restore_video_wallpaper.sh"
THUMBNAIL_DIR="$RESTORE_SCRIPT_DIR/mpvpaper_thumbnails"
VIDEO_OPTS="no-audio loop hwdec=auto scale=bilinear interpolation=no video-sync=display-resample panscan=1.0 video-scale-x=1.0 video-scale-y=1.0 video-align-x=0.5 video-align-y=0.5 load-scripts=no"

is_video() {
    local extension="${1##*.}"
    [[ "$extension" == "mp4" || "$extension" == "webm" || "$extension" == "mkv" || "$extension" == "avi" || "$extension" == "mov" ]] && return 0 || return 1
}

kill_existing_mpvpaper() {
    pkill -f -9 mpvpaper || true
}

create_restore_script() {
    local video_path=$1
    cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# Generated by switchwall.sh - Don't modify it by yourself.
# Time: $(date)

pkill -f -9 mpvpaper

for monitor in \$(hyprctl monitors -j | jq -r '.[] | .name'); do
    mpvpaper -o "$VIDEO_OPTS" "\$monitor" "$video_path" &
    sleep 0.1
done
EOF
    mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
    chmod +x "$RESTORE_SCRIPT"
}

remove_restore() {
    cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# The content of this script will be generated by switchwall.sh - Don't modify it by yourself.
EOF
    mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
}

set_wallpaper_path() {
    local path="$1"
    if [[ -z "$path" || -d "$path" || ! -f "$path" ]]; then
        return 1
    fi
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.wallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

set_dark_wallpaper_path() {
    local path="$1"
    if [[ -z "$path" || -d "$path" || ! -f "$path" ]]; then
        return 1
    fi
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.darkWallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

set_light_wallpaper_path() {
    local path="$1"
    if [[ -z "$path" || -d "$path" || ! -f "$path" ]]; then
        return 1
    fi
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.lightWallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

set_thumbnail_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.thumbnailPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

categorize_wallpaper() {
    img_cat=$("$SCRIPT_DIR/../ai/gemini-categorize-wallpaper.sh" "$1")
    # notify-send "Wallpaper category" "$img_cat"
    echo "$img_cat" > "$STATE_DIR/user/generated/wallpaper/category.txt"
}

switch() {
    imgpath="$1"
    mode_flag="$2"
    type_flag="$3"
    color_flag="$4"
    color="$5"
    noswitch_flag="$6"

    # Start Gemini auto-categorization if enabled (only on wallpaper change)
    if [[ "$noswitch_flag" != "1" ]]; then
        aiStylingEnabled=$(jq -r '.background.widgets.clock.cookie.aiStyling' "$SHELL_CONFIG_FILE")
        if [[ "$aiStylingEnabled" == "true" ]]; then
            categorize_wallpaper "$imgpath" &
        fi
    fi

    matugen_args=(--source-color-index 0)

    if [[ "$color_flag" == "1" ]]; then
        matugen_args+=(color hex "$color")
        generate_colors_material_args=(--color "$color")
    else
        if [[ -z "$imgpath" || -d "$imgpath" || ! -f "$imgpath" ]]; then
            echo "[switchwall.sh] Aborted: '$imgpath' is not a valid image file" >&2
            exit 1
        fi

        if [[ "$noswitch_flag" != "1" ]]; then
            check_and_prompt_upscale "$imgpath" &
            kill_existing_mpvpaper
        fi

        if is_video "$imgpath"; then
            mkdir -p "$THUMBNAIL_DIR"

            missing_deps=()
            if ! command -v mpvpaper &> /dev/null; then
                missing_deps+=("mpvpaper")
            fi
            if ! command -v ffmpeg &> /dev/null; then
                missing_deps+=("ffmpeg")
            fi
            if [ ${#missing_deps[@]} -gt 0 ]; then
                echo "Missing deps: ${missing_deps[*]}"
                echo "Arch: yay -S ${missing_deps[*]}"
                action=$(notify-send \
                    -a "Wallpaper switcher" \
                    -c "im.error" \
                    -A "install_arch=Install (Arch)" \
                    "Can't switch to video wallpaper" \
                    "Missing dependencies: ${missing_deps[*]}")
                if [[ "$action" == "install_arch" ]]; then
                    if command -v yay &>/dev/null; then
                        kitty -1 yay -S "${missing_deps[*]}"
                    else
                        kitty -1 sudo pacman -S "${missing_deps[*]}"
                    fi
                    if command -v mpvpaper &>/dev/null && command -v ffmpeg &>/dev/null; then
                        notify-send 'Wallpaper switcher' 'Alright, try again!' -a "Wallpaper switcher"
                    fi
                fi
                exit 0
            fi

            # Set wallpaper path
            set_wallpaper_path "$imgpath"

            # Set video wallpaper
            local video_path="$imgpath"
            monitors=$(hyprctl monitors -j | jq -r '.[] | .name')
            for monitor in $monitors; do
                mpvpaper -o "$VIDEO_OPTS" "$monitor" "$video_path" &
                sleep 0.1
            done

            # Extract first frame for color generation
            thumbnail="$THUMBNAIL_DIR/$(basename "$imgpath").jpg"
            ffmpeg -y -i "$imgpath" -vframes 1 "$thumbnail" 2>/dev/null

            # Set thumbnail path
            set_thumbnail_path "$thumbnail"

            if [ -f "$thumbnail" ]; then
                matugen_args+=(image "$thumbnail")
                generate_colors_material_args=(--path "$thumbnail")
                create_restore_script "$video_path"
            else
                echo "Cannot create image to colorgen"
                remove_restore
                exit 1
            fi
        else
            matugen_args+=(image "$imgpath")
            generate_colors_material_args=(--path "$imgpath")
            # Update wallpaper path in config
            local cur_saved_path="$(jq -r '.background.wallpaperPath // empty' "$SHELL_CONFIG_FILE" 2>/dev/null)"
            if [[ "$noswitch_flag" != "1" || "$imgpath" != "$cur_saved_path" ]]; then
                set_wallpaper_path "$imgpath"
                remove_restore
            fi
        fi
    fi

    # Determine mode if not set
    if [[ -z "$mode_flag" ]]; then
        current_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
        if [[ "$current_mode" == "prefer-dark" ]]; then
            mode_flag="dark"
        else
            mode_flag="light"
        fi
    fi

    # enforce dark mode for terminal
    if [[ -n "$mode_flag" ]]; then
        matugen_args+=(--mode "$mode_flag")
        if [[ $(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode' "$SHELL_CONFIG_FILE") == "true" ]]; then
            generate_colors_material_args+=(--mode "dark")
        else
            generate_colors_material_args+=(--mode "$mode_flag")
        fi
    fi
    [[ -n "$type_flag" ]] && matugen_args+=(--type "$type_flag") && generate_colors_material_args+=(--scheme "$type_flag")
    generate_colors_material_args+=(--termscheme "$terminalscheme" --blend_bg_fg)
    generate_colors_material_args+=(--cache "$STATE_DIR/user/generated/color.txt")

    pre_process "$mode_flag"

    # Check if app and shell theming is enabled in config
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        enable_apps_shell=$(jq -r '.appearance.wallpaperTheming.enableAppsAndShell' "$SHELL_CONFIG_FILE")
        if [ "$enable_apps_shell" == "false" ]; then
            echo "App and shell theming disabled, skipping matugen and color generation"
            return
        fi
    fi

    # Set harmony and related properties
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        harmony=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.harmony' "$SHELL_CONFIG_FILE")
        harmonize_threshold=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold' "$SHELL_CONFIG_FILE")
        term_fg_boost=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost' "$SHELL_CONFIG_FILE")
        [[ "$harmony" != "null" && -n "$harmony" ]] && generate_colors_material_args+=(--harmony "$harmony")
        [[ "$harmonize_threshold" != "null" && -n "$harmonize_threshold" ]] && generate_colors_material_args+=(--harmonize_threshold "$harmonize_threshold")
        [[ "$term_fg_boost" != "null" && -n "$term_fg_boost" ]] && generate_colors_material_args+=(--term_fg_boost "$term_fg_boost")
    fi

    matugen "${matugen_args[@]}"
    source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
    python3 "$SCRIPT_DIR/generate_colors_material.py" "${generate_colors_material_args[@]}" \
        > "$STATE_DIR"/user/generated/material_colors.scss
    deactivate
    "$SCRIPT_DIR"/applycolor.sh

    # Pass screen width, height, and wallpaper path to post_process
    post_process "" "" "$imgpath"
}

main() {
    imgpath=""
    mode_flag=""
    type_flag=""
    color_flag=""
    color=""
    noswitch_flag=""

    get_type_from_config() {
        jq -r '.appearance.palette.type' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "auto"
    }
    get_accent_color_from_config() {
        jq -r '.appearance.palette.accentColor' "$SHELL_CONFIG_FILE" 2>/dev/null || echo ""
    }
    set_accent_color() {
        local color="$1"
        jq --arg color "$color" '.appearance.palette.accentColor = $color' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    }

    detect_scheme_type_from_image() {
        local img="$1"
        source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
        "$SCRIPT_DIR"/scheme_for_image.py "$img" 2>/dev/null | tr -d '\n'
        deactivate
    }

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)
                mode_flag="$2"
                shift 2
                ;;
            --type)
                type_flag="$2"
                shift 2
                ;;
            --color)
                if [[ "$2" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
                    set_accent_color "$2"
                    shift 2
                elif [[ "$2" == "clear" ]]; then
                    set_accent_color ""
                    shift 2
                else
                    set_accent_color $(hyprpicker --no-fancy)
                    shift
                fi
                ;;
            --dark-image)
                local dark_arg="$2"
                set_dark_wallpaper_path "$dark_arg"
                if [[ "$mode_flag" == "dark" ]] || { [[ -z "$mode_flag" ]] && gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | grep -q "prefer-dark"; }; then
                    imgpath="$dark_arg"
                fi
                shift 2
                ;;
            --light-image)
                local light_arg="$2"
                set_light_wallpaper_path "$light_arg"
                if [[ "$mode_flag" == "light" ]] || { [[ -z "$mode_flag" ]] && ! gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | grep -q "prefer-dark"; }; then
                    imgpath="$light_arg"
                fi
                shift 2
                ;;
            --image)
                imgpath="$2"
                if [[ "$mode_flag" == "dark" ]]; then
                    set_dark_wallpaper_path "$imgpath"
                elif [[ "$mode_flag" == "light" ]]; then
                    set_light_wallpaper_path "$imgpath"
                fi
                shift 2
                ;;
            --noswitch)
                noswitch_flag="1"
                local cfg_dark="$(jq -r '.background.darkWallpaperPath // empty' "$SHELL_CONFIG_FILE" 2>/dev/null)"
                local cfg_light="$(jq -r '.background.lightWallpaperPath // empty' "$SHELL_CONFIG_FILE" 2>/dev/null)"
                local eff_mode="$mode_flag"
                if [[ -z "$eff_mode" ]]; then
                    if gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | grep -q "prefer-dark"; then
                        eff_mode="dark"
                    else
                        eff_mode="light"
                    fi
                fi
                if [[ "$eff_mode" == "dark" && -n "$cfg_dark" && -f "$cfg_dark" && ! -d "$cfg_dark" ]]; then
                    imgpath="$cfg_dark"
                elif [[ "$eff_mode" == "light" && -n "$cfg_light" && -f "$cfg_light" && ! -d "$cfg_light" ]]; then
                    imgpath="$cfg_light"
                else
                    imgpath=$(jq -r '.background.wallpaperPath // empty' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "")
                    if [[ -z "$imgpath" || -d "$imgpath" || ! -f "$imgpath" ]]; then
                        if [[ -n "$cfg_dark" && -f "$cfg_dark" && ! -d "$cfg_dark" ]]; then
                            imgpath="$cfg_dark"
                        elif [[ -n "$cfg_light" && -f "$cfg_light" && ! -d "$cfg_light" ]]; then
                            imgpath="$cfg_light"
                        fi
                    fi
                fi
                shift
                ;;
            *)
                if [[ -z "$imgpath" ]]; then
                    imgpath="$1"
                fi
                shift
                ;;
        esac
    done

    # If accentColor is set in config, use it
    config_color="$(get_accent_color_from_config)"
    if [[ "$config_color" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
        color_flag="1"
        color="$config_color"
    fi

    # If type_flag is not set, get it from config
    if [[ -z "$type_flag" ]]; then
        type_flag="$(get_type_from_config)"
    fi

    # Validate type_flag (allow 'auto' as well)
    allowed_types=(scheme-content scheme-expressive scheme-fidelity scheme-fruit-salad scheme-monochrome scheme-neutral scheme-rainbow scheme-tonal-spot auto)
    valid_type=0
    for t in "${allowed_types[@]}"; do
        if [[ "$type_flag" == "$t" ]]; then
            valid_type=1
            break
        fi
    done
    if [[ $valid_type -eq 0 ]]; then
        echo "[switchwall.sh] Warning: Invalid type '$type_flag', defaulting to 'auto'" >&2
        type_flag="auto"
    fi

    # Only prompt for wallpaper if not using --color and not using --noswitch and no imgpath set
    if [[ -z "$imgpath" && -z "$color_flag" && -z "$noswitch_flag" ]]; then
        cd "$(xdg-user-dir PICTURES)/Wallpapers/showcase" 2>/dev/null || cd "$(xdg-user-dir PICTURES)/Wallpapers" 2>/dev/null || cd "$(xdg-user-dir PICTURES)" || return 1
        imgpath="$(kdialog --getopenfilename . --title 'Choose wallpaper')"
    fi

    if [[ -n "$imgpath" && -z "$noswitch_flag" ]]; then
        set_accent_color ""
        color_flag=""
        color=""
    fi

    # If type_flag is 'auto', detect scheme type from image (after imgpath is set)
    if [[ "$type_flag" == "auto" ]]; then
        if [[ -n "$imgpath" && -f "$imgpath" ]]; then
            detected_type="$(detect_scheme_type_from_image "$imgpath")"
            # Only use detected_type if it's valid
            valid_detected=0
            for t in "${allowed_types[@]}"; do
                if [[ "$detected_type" == "$t" && "$detected_type" != "auto" ]]; then
                    valid_detected=1
                    break
                fi
            done
            if [[ $valid_detected -eq 1 ]]; then
                type_flag="$detected_type"
            else
                echo "[switchwall] Warning: Could not auto-detect a valid scheme, defaulting to 'scheme-tonal-spot'" >&2
                type_flag="scheme-tonal-spot"
            fi
        else
            echo "[switchwall] Warning: No image to auto-detect scheme from, defaulting to 'scheme-tonal-spot'" >&2
            type_flag="scheme-tonal-spot"
        fi
    fi

    # If mode_flag is dark or light, select configured wallpaper or suffix variant
    if [[ "$mode_flag" == "dark" || "$mode_flag" == "light" ]]; then
        local configured_target=""
        if [[ "$mode_flag" == "dark" ]]; then
            configured_target="$(jq -r '.background.darkWallpaperPath // empty' "$SHELL_CONFIG_FILE" 2>/dev/null)"
        else
            configured_target="$(jq -r '.background.lightWallpaperPath // empty' "$SHELL_CONFIG_FILE" 2>/dev/null)"
        fi

        if [[ "$noswitch_flag" == "1" && -n "$configured_target" && -f "$configured_target" ]]; then
            imgpath="$configured_target"
        elif [[ "$noswitch_flag" == "1" ]]; then
            # Get directory, filename without extension, and extension
            local imgdir="$(dirname "$imgpath")"
            local imgbase="$(basename "$imgpath")"
            local imgname="${imgbase%.*}"
            local imgext="${imgbase##*.}"

            # Strip existing -dark or -light suffix
            local stripped_name="${imgname%-dark}"
            stripped_name="${stripped_name%-light}"

            # Construct the new path with the requested mode suffix
            local new_imgpath="${imgdir}/${stripped_name}-${mode_flag}.${imgext}"
            local new_stripped_imgpath="${imgdir}/${stripped_name}.${imgext}"

            # If the variant exists, use it
            if [[ -f "$new_imgpath" ]]; then
                imgpath="$new_imgpath"
            elif [[ -f "$new_stripped_imgpath" ]]; then
                imgpath="$new_stripped_imgpath"
            fi
        fi
    fi

    switch "$imgpath" "$mode_flag" "$type_flag" "$color_flag" "$color" "$noswitch_flag"
}

main "$@"
