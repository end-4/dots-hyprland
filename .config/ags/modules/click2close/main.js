const { Gdk } = imports.gi;
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import PopupWindow from '../.widgethacks/popupwindow.js';
import { monitors } from '../.miscutils/hyprlanddata.js';

const WINDOWS_NEED_CLICK2CLOSE = [
    'sideleft', 'sideright', 'overview', 'cheatsheet'
];

const range = (length, start = 1) => Array.from({ length }, (_, i) => i + start);

export default (monitor = 0) => PopupWindow({
    monitor,
    name: `click2close${monitor}`,
    layer: 'top',
    anchor: ['top', 'bottom', 'left', 'right'],
    exclusivity: 'ignore',
    child: Widget.EventBox({
        attribute: {
            checkWindowRelevance: (currentName) => {
                let relevant = false;
                // use regex to check if name matches one of windows need click2close with a *
                for (let i = 0; i < WINDOWS_NEED_CLICK2CLOSE.length; i++) {
                    const testRegex = RegExp(`^${WINDOWS_NEED_CLICK2CLOSE[i]}\\d*$`);
                    if (testRegex.test(currentName)) {
                        relevant = true;
                        break;
                    }
                }
                return relevant;
            }
        },
        onPrimaryClick: () => closeEverything(),
        onSecondaryClick: () => closeEverything(),
        onMiddleClick: () => closeEverything(),
        setup: (self) => self.hook(App, (self, currentName, visible) => {
            if(!self.attribute.checkWindowRelevance(currentName)) return;
            range(Gdk.Display.get_default()?.get_n_monitors() || 1, 0).forEach(id => {
                if(visible) App.openWindow(`click2close${id}`);
                else App.closeWindow(`click2close${id}`);
            });
        }),
        child: Widget.Box({
            css: `
                ${userOptions.appearance.layerSmoke ? 'background-color: rgba(0,0,0,' + String(userOptions.appearance.layerSmokeStrength) + ');' : ''}
                min-height: ${monitors[monitor].height}px;
                min-width: ${monitors[monitor].width}px;
            `
        }),
    })
});