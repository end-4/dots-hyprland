const { Gio, GLib } = imports.gi;
import GtkSource from "gi://GtkSource?version=3.0";
import App from 'resource:///com/github/Aylur/ags/app.js'
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
import { darkMode } from './modules/.miscutils/system.js';

const CUSTOM_SOURCEVIEW_SCHEME_PATH = `${App.configDir}/assets/themes/sourceviewtheme${darkMode.value ? '' : '-light'}.xml`;

export const COMPILED_STYLE_DIR = `${GLib.get_user_cache_dir()}/ags/user/generated`

function loadSourceViewColorScheme(filePath) {
    // Read the XML file content
    const file = Gio.File.new_for_path(filePath);
    const [success, contents] = file.load_contents(null);

    if (!success) {
        logError('Failed to load the XML file.');
        return;
    }

    // Parse the XML content and set the Style Scheme
    const schemeManager = GtkSource.StyleSchemeManager.get_default();
    schemeManager.append_search_path(file.get_parent().get_path());
}

globalThis['handleStyles'] = (resetMusic) => {
    // Reset
    Utils.exec(`mkdir -p "${GLib.get_user_state_dir()}/ags/scss"`);
    if (resetMusic) {
        Utils.exec(`bash -c 'echo "" > ${GLib.get_user_state_dir()}/ags/scss/_musicwal.scss'`); // reset music styles
        Utils.exec(`bash -c 'echo "" > ${GLib.get_user_state_dir()}/ags/scss/_musicmaterial.scss'`); // reset music styles
    }
    // Generate overrides
    let lightdark = darkMode.value ? "dark" : "light";
    Utils.writeFileSync(
        `
@mixin symbolic-icon {
    -gtk-icon-theme: '${userOptions.icons.symbolicIconTheme[lightdark]}';
}
`,
        `${GLib.get_user_state_dir()}/ags/scss/_lib_mixins_overrides.scss`)
    // Compile and apply
    async function applyStyle() {
        Utils.exec(`mkdir -p ${COMPILED_STYLE_DIR}`);
        Utils.exec(`sass -I "${GLib.get_user_state_dir()}/ags/scss" -I "${App.configDir}/scss/fallback" "${App.configDir}/scss/main.scss" "${COMPILED_STYLE_DIR}/style.css"`);
        App.resetCss();
        App.applyCss(`${COMPILED_STYLE_DIR}/style.css`);
        console.log('[LOG] Styles loaded')
    }
    applyStyle().then(() => {
        loadSourceViewColorScheme(CUSTOM_SOURCEVIEW_SCHEME_PATH);
    }).catch(print);
}
