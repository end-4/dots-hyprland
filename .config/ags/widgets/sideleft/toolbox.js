import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, EventBox, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import QuickScripts from './tools/quickscripts.js';
import ColorPicker from './tools/colorpicker.js';

export default Scrollable({
    hscroll: "never",
    vscroll: "automatic",
    child: Box({
        vertical: true,
        className: 'spacing-v-10',
        children: [
            QuickScripts(),
            ColorPicker(),
        ]
    })
});
