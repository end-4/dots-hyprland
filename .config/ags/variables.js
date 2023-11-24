import Variable from 'resource:///com/github/Aylur/ags/variable.js';

export const showMusicControls = Variable(false, {})
export const showColorScheme = Variable(false, {})
globalThis['openMusicControls'] = showMusicControls;
globalThis['openColorScheme'] = showColorScheme;
