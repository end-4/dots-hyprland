import GtkSource from "gi://GtkSource?version=3.0";
import { darkMode } from './modules/core/miscutils/system.js';
import { exec, writeFile, Gio, GLib } from "astal";
import { App } from "astal/gtk3";
import { userOptions } from "./modules/core/configuration/user_options.js";


const CUSTOM_SOURCEVIEW_SCHEME_PATH = `${GLib.get_user_config_dir()}/agsv2/assets/themes/sourceviewtheme${darkMode.get() ? '' : '-light'}.xml`;

export const COMPILED_STYLE_DIR = `${GLib.get_user_cache_dir()}/agsv2/user/generated`

function loadSourceViewColorScheme(filePath: string) {
    // Read the XML file content
    const file = Gio.File.new_for_path(filePath);
    const [success, contents] = file.load_contents(null);

    if (!success) {
        logError('Failed to load the XML file.');
        return;
    }

    // Parse the XML content and set the Style Scheme
    const schemeManager = GtkSource.StyleSchemeManager.get_default();
    schemeManager.append_search_path(file.get_parent()!.get_path()!);
}

export function handleStyles(resetMusic: boolean) {
    // Reset
    exec(`mkdir -p "${GLib.get_user_state_dir()}/agsv2/scss"`);
    if (resetMusic) {
        exec(`bash -c 'echo "" > ${GLib.get_user_state_dir()}/agsv2/scss/_musicwal.scss'`); // reset music styles
        exec(`bash -c 'echo "" > ${GLib.get_user_state_dir()}/agsv2/scss/_musicmaterial.scss'`); // reset music styles
    }
    // Generate overrides
    const lightdark = darkMode.get() ? "dark" : "light";
    writeFile(
        `${GLib.get_user_state_dir()}/agsv2/scss/_lib_mixins_overrides.scss`,
        `
@mixin symbolic-icon {
    -gtk-icon-theme: '${userOptions.icons.symbolicIconTheme[lightdark]}';
}
`)
    // Compile and apply
    async function applyStyle() {
        exec(`mkdir -p ${COMPILED_STYLE_DIR}`);
        exec(`sass -I "${GLib.get_user_state_dir()}/agsv2/scss" -I "${GLib.get_user_config_dir()}/agsv2/scss/fallback" "${GLib.get_user_config_dir()}/agsv2/scss/main.scss" "${COMPILED_STYLE_DIR}/style.css"`);
        App.reset_css();
        App.apply_css(`${COMPILED_STYLE_DIR}/style.css`);
        console.log('[LOG] Styles loaded')
    }
    applyStyle().then(() => {
        loadSourceViewColorScheme(CUSTOM_SOURCEVIEW_SCHEME_PATH);
    }).catch(print);
}
