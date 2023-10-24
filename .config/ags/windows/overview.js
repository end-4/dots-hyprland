import { Widget } from '../imports.js';
import { SearchAndWindows } from "../modules/overview.js";

export default () => Widget.Window({
    name: 'overview',
    exclusive: false,
    focusable: true,
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
