const { Service, Widget } = ags;
const { Applications } = ags.Service;
import { SearchAndWindows } from "../modules/overview.js";

export const overview = Widget.Window({
    name: 'overview',
    exclusive: false,
    focusable: true,
    popup: true,
    anchor: ['top'],
    child: Widget.Box({
        vertical: true,
        children: [
            SearchAndWindows(),
        ]
    }),
})
