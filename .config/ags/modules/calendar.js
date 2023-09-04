const { App, Widget } = ags;
const { Box, CenterBox, Label } = ags.Widget;
const { Mpris } = ags.Service;
const { exec, execAsync, timeout } = ags.Utils;
import { MenuService } from "./sideright.js";
import { BluetoothIndicator, NetworkIndicator } from "./statusicons.js";
import { MaterialIcon } from "./lib/materialicon.js";

let calendarJson = JSON.parse(exec(`${App.configDir}/scripts/calendarlayout`));
const weekDays = [
    { day: 'Mo', today: 0 },
    { day: 'Tu', today: 0 },
    { day: 'We', today: 0 },
    { day: 'Th', today: 0 },
    { day: 'Fr', today: 0 },
    { day: 'Sa', today: 0 },
    { day: 'Su', today: 0 },
]

const CalendarDay = (day, today) => Widget.Button({
    className: `sidebar-calendar-btn ${today == 1 ? 'sidebar-calendar-btn-today' : (today == -1 ? 'sidebar-calendar-btn-othermonth' : '')}`,
    child: Label({
        className: 'txt-smallie',
        label: String(day),
    })
})

export const ModuleCalendar = () => Box({
    className: 'sidebar-group spacing-h-5',
    setup: (box) => {
        box.pack_start(Box({
            valign: 'center',
            homogeneous: true,
            vertical: true,
            className: 'sidebar-navrail spacing-v-10',
            children: [
                // Calendar
                Widget.Button({
                    className: 'button-minsize sidebar-navrail-btn sidebar-button-alone txt-small spacing-h-5',
                    child: Box({
                        className: 'spacing-v-5',
                        vertical: true,
                        children: [
                            MaterialIcon('calendar_month', 'hugeass'),
                            Label({
                                label: 'Calendar',
                                className: 'txt txt-smallie',
                            }),
                        ]
                    })
                }),
                // To Do
                Widget.Button({
                    className: 'button-minsize sidebar-navrail-btn sidebar-button-alone txt-small spacing-h-5',
                    child: Box({
                        className: 'spacing-v-5',
                        vertical: true,
                        children: [
                            MaterialIcon('lists', 'hugeass'),
                            Label({
                                label: 'To Do',
                                className: 'txt txt-smallie',
                            }),
                        ]
                    })
                }),
                // Ideas
                Widget.Button({
                    className: 'button-minsize sidebar-navrail-btn sidebar-button-alone txt-small spacing-h-5',
                    child: Box({
                        className: 'spacing-v-5',
                        vertical: true,
                        children: [
                            MaterialIcon('edit', 'hugeass'),
                            Label({
                                label: 'Stars',
                                className: 'txt txt-smallie',
                            }),
                        ]
                    })
                }),
            ]
        }), false, false, 0);
        // ags.Widget({ // TDOO: replace this sad default calendar with a custom one
        //     type: imports.gi.Gtk.Calendar,
        // }),
        box.pack_end(Widget.Box({
            hexpand: true,
            vertical: true,
            className: 'spacing-v-5',
            children: [
                Widget.Box({
                    homogeneous: true,
                    className: 'spacing-h-5',
                    children: weekDays.map((day, i) =>
                        CalendarDay(day.day, day.today)
                    )
                }),
                ...calendarJson.map((row, i) => Widget.Box({
                    homogeneous: true,
                    className: 'spacing-h-5',
                    children: row.map((day, i) =>
                        CalendarDay(day.day, day.today)
                    )
                }))
            ]
        }), false, false, 0);
    }
})