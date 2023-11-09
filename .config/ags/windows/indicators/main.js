import { Widget } from '../../imports.js';
import Indicator from '../../scripts/indicator.js';
import IndicatorValues from './indicatorvalues.js';
import MusicControls from './musiccontrols.js';
import NotificationPopups from './notificationpopups.js';

export default (monitor) => Widget.Window({
    name: `indicator${monitor}`,
    monitor,
    className: 'indicator',
    layer: 'overlay',
    visible: true,
    anchor: ['top'],
    child: Widget.EventBox({
        onHover: () => { //make the widget hide when hovering
            Indicator.popup(-1);
        },
        child: Widget.Box({
            vertical: true,
            css: 'min-height: 2px;',
            children: [
                IndicatorValues(),
                MusicControls(),
                NotificationPopups(),
            ]
        })
    }),
});
