import { App, Gdk, Gtk } from 'astal/gtk3';
import { init as i18n_init } from './i18n/i18n'
import { GLib, Variable } from 'astal';
import { userOptions } from './modules/core/configuration/user_options';
import AstalHyprland from 'gi://AstalHyprland';
//init i18n, Load language file
i18n_init()
Gtk.IconTheme.get_default().append_search_path(`${GLib.get_user_config_dir}/agsv2/assets/icons`);

// Global vars for external control (through keybinds)
export const showMusicControls = Variable(false)
export const showColorScheme = Variable(false)
// load monitor shell modes from userOptions
const initialMonitorShellModes = () => {
    const numberOfMonitors = Gdk.Display.get_default()?.get_n_monitors() || 1;
    const monitorBarConfigs: string[] = [];
    for (let i = 0; i < numberOfMonitors; i++) {
        if (userOptions.bar.modes[i]) {
            monitorBarConfigs.push(userOptions.bar.modes[i])
        } else {
            monitorBarConfigs.push('normal')
        }
    }
    return monitorBarConfigs;

}
export const currentShellMode = Variable(initialMonitorShellModes()) // normal, focus

// Mode switching
const updateMonitorShellMode = (monitorShellModes: Variable<string[]>, monitor: number, mode: string) => {
    const newValue = [...monitorShellModes.get()];
    newValue[monitor] = mode;
    monitorShellModes.set(newValue);
}
export function cycleMode() {
    const monitor = AstalHyprland.get_default().focusedMonitor.id || 0;

    if (currentShellMode.get()[monitor] === 'normal') {
        updateMonitorShellMode(currentShellMode, monitor, 'focus')
    }
    else if (currentShellMode.get()[monitor] === 'focus') {
        updateMonitorShellMode(currentShellMode, monitor, 'nothing')
    }
    else {
        updateMonitorShellMode(currentShellMode, monitor, 'normal')
    }
}

// Window controls
const range = (length: number, start = 1) => Array.from({ length }, (_, i) => i + start);

export function toggleWindowOnAllMonitors(name: string) {
    range(Gdk.Display.get_default()?.get_n_monitors() || 1, 0).forEach(id => {
        App.toggle_window(`${name}${id}`);
    });
}
export function closeWindowOnAllMonitors(name: string) {
    range(Gdk.Display.get_default()?.get_n_monitors() || 1, 0).forEach(id => {
        App.remove_window(App.get_window(`${name}${id}`)!);
    });
}
export function openWindowOnAllMonitors(name: string) {
    range(Gdk.Display.get_default()?.get_n_monitors() || 1, 0).forEach(id => {
        // TODO: Test it because I'm sure this does not work
        App.add_window(App.get_window(`${name}${id}`)!);
    });
}

export function closeEverything() {
    const numMonitors = Gdk.Display.get_default()?.get_n_monitors() || 1;
    for (let i = 0; i < numMonitors; i++) {
        App.remove_window(App.get_window(`cheatsheet${i}`)!);
        App.remove_window(App.get_window(`session${i}`)!);
    }
    App.remove_window(App.get_window('sideleft')!);
    App.remove_window(App.get_window('sideright')!);
    App.remove_window(App.get_window('overview')!);
};
