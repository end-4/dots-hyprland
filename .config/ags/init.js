import GLib from 'gi://GLib';
import App from 'resource:///com/github/Aylur/ags/app.js'
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
import { darkMode } from './modules/.miscutils/system.js';

export const COMPILED_STYLE_DIR = `${GLib.get_user_cache_dir()}/ags/user/generated`

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
`@mixin symbolic-icon {
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
    applyStyle().catch(print);
}
