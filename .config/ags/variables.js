const { Gtk } = imports.gi;
import Variable from 'resource:///com/github/Aylur/ags/variable.js';
import Mpris from 'resource:///com/github/Aylur/ags/service/mpris.js';
const { exec, execAsync } = Utils;

Gtk.IconTheme.get_default().append_search_path(`${App.configDir}/assets/icons`);

// Global vars for external control (through keybinds)
export const showMusicControls = Variable(false, {})
export const showColorScheme = Variable(false, {})
globalThis['openMusicControls'] = showMusicControls;
globalThis['openColorScheme'] = showColorScheme;

globalThis['mpris'] = Mpris;

// Screen size
export const SCREEN_WIDTH = Number(exec(`bash -c "xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f1 | head -1" | awk '{print $1}'`));
export const SCREEN_HEIGHT = Number(exec(`bash -c "xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f2 | head -1" | awk '{print $1}'`));

// Caculated scaled size 
let scale_factor = 1;
try {
    scale_factor = JSON.parse(exec('hyprctl monitors -j'))
        .filter(monitor => monitor.focused)[0]
        .scale;
} catch {}
export const SCALE_FACTOR = scale_factor;
export const SCREEN_REAL_WIDTH = SCREEN_WIDTH / SCALE_FACTOR;
export const SCREEN_REAL_HEIGHT = SCREEN_HEIGHT / SCALE_FACTOR;

// Mode switching
export const currentShellMode = Variable('normal', {}) // normal, focus
globalThis['currentMode'] = currentShellMode;
globalThis['cycleMode'] = () => {
    if (currentShellMode.value === 'normal') {
        currentShellMode.value = 'focus';
    } else {
        currentShellMode.value = 'normal';
    }
}
