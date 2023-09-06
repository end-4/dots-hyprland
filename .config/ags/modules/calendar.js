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
        className: 'txt-smallie txt-semibold',
        label: String(day),
    })
})

const calendarWidget = Widget.Box({
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
})

const defaultShown = 'calendar';
const contentStack = Widget.Stack({
    hexpand: true,
    items: [
        ['calendar', calendarWidget],
        ['todo', Widget.Label({ label: 'To Do list will be here' })],
        ['stars', Widget.Label({ label: 'Stars will be here' })],
    ],
    transition: 'slide_up_down',
    transitionDuration: 180,
    setup: (stack) => {
        stack.shown = defaultShown;
    }
})

const StackButton = (parentBox, stackItemName, icon, name) => Widget.Button({
    className: 'button-minsize sidebar-navrail-btn sidebar-button-alone txt-small spacing-h-5',
    onPrimaryClick: (button) => {
        contentStack.shown = stackItemName;
        const kids = parentBox.get_children()[0].get_children();
        for (let i = 0; i < kids.length; i++) {
            kids[i].toggleClassName('sidebar-navrail-btn-active', false);
        }
        button.toggleClassName('sidebar-navrail-btn-active', true);
    },
    child: Box({
        className: 'spacing-v-5',
        vertical: true,
        children: [
            MaterialIcon(icon, 'hugeass'),
            Label({
                label: name,
                className: 'txt txt-smallie',
            }),
        ]
    }),
    setup: (button) => {
        button.toggleClassName('sidebar-navrail-btn-active', defaultShown === stackItemName);
    }
});

export const ModuleCalendar = () => Box({
    className: 'sidebar-group spacing-h-5',
    setup: (box) => {
        box.pack_start(Box({
            valign: 'center',
            homogeneous: true,
            vertical: true,
            className: 'sidebar-navrail spacing-v-10',
            children: [
                StackButton(box, 'calendar', 'calendar_month', 'Calendar'),
                StackButton(box, 'todo', 'lists', 'To Do'),
                StackButton(box, 'stars', 'star', 'Stars'),
            ]
        }), false, false, 0);
        // ags.Widget({ // TDOO: replace this sad default calendar with a custom one
        //     type: imports.gi.Gtk.Calendar,
        // }),
        box.pack_end(contentStack, false, false, 0);
    }
})

// Example stack widget
const NetworkWiredIndicator = () => Widget.Stack({
    items: [
        ['unknown', Widget.Label({ className: 'txt-norm icon-material', label: 'wifi_off' })],
        ['disconnected', Widget.Label({ className: 'txt-norm icon-material', label: 'signal_wifi_off' })],
        ['disabled', Widget.Label({ className: 'txt-norm icon-material', label: 'signal_wifi_statusbar_not_connected' })],
        ['connected', Widget.Label({ className: 'txt-norm icon-material', label: 'lan' })],
        ['connecting', Widget.Label({ className: 'txt-norm icon-material', label: 'signal_wifi_0_bar' })],
    ],
    connections: [[Network, stack => {
        if (!Network.wired)
            return;

        const { internet } = Network.wired;
        if (internet === 'connected' || internet === 'connecting')
            stack.shown = internet;

        if (Network.connectivity !== 'full')
            stack.shown = 'disconnected';

        stack.shown = 'disabled';
    }]],
});