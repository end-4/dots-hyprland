import Variable from 'resource:///com/github/Aylur/ags/variable.js';

// AGS Variables
export const showMusicControls = Variable(false, {})
export const showColorScheme = Variable(false, {})
export const tray = Variable({
    iconSize: 20,
    gap:10
})


globalThis['openMusicControls'] = showMusicControls;
globalThis['openColorScheme'] = showColorScheme;
globalThis['trayPreferences'] = tray;