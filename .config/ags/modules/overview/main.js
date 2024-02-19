import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { SearchAndWindows } from "./windowcontent.js";

export default () => Widget.Window({
    name: 'overview',
    exclusivity: 'ignore',
    keymode: 'exclusive',
    popup: true,
    visible: false,
    anchor: ['top'],
    layer: 'overlay',
    child: Widget.Box({
        vertical: true,
        children: [
            SearchAndWindows(),
        ]
    }),
})
