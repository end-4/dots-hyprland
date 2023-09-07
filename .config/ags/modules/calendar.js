const { App, Widget } = ags;
const { Box, CenterBox, Label } = ags.Widget;
const { Mpris } = ags.Service;
const { exec, execAsync, timeout } = ags.Utils;
import { MenuService } from "./sideright.js";
import { BluetoothIndicator, NetworkIndicator } from "./statusicons.js";
import { MaterialIcon } from "./lib/materialicon.js";
import { getCalendarLayout } from "../scripts/calendarlayout.js";

let calendarJson = getCalendarLayout(undefined, true);
console.log(calendarJson);
let todoJson = JSON.parse(ags.Utils.readFile(`${App.configDir}/data/todo.json`));

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

const todoWidget = Widget.Box({
    hexpand: true,
    vertical: true,
    className: 'spacing-v-5',
    children: [
        Widget.Label({
            className: 'txt txt-large',
            label: 'Tasks & Ideas',
        }),
        Widget.Box({
            vertical: true,
            children: todoJson.map((task, i) => Widget.Box({
                children: [
                    Widget.Button({
                        child: MaterialIcon('remove', 'norm'),
                    }),
                    Widget.Label({
                        hexpand: true,
                        xalign: 0,
                        wrap: true,
                        className: 'txt txt-smallie sidebar-todo-txt',
                        label: task.content,
                    })
                ]
            }))
        }),
    ]
})

const defaultShown = 'calendar';
const contentStack = Widget.Stack({
    hexpand: true,
    items: [
        ['calendar', calendarWidget],
        ['todo', todoWidget],
        ['stars', Widget.Label({ label: 'GitHub feed will be here' })],
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
                StackButton(box, 'stars', 'star', 'GitHub'),
            ]
        }), false, false, 0);
        // ags.Widget({ // TDOO: replace this sad default calendar with a custom one
        //     type: imports.gi.Gtk.Calendar,
        // }),
        box.pack_end(contentStack, false, false, 0);
    }
})


// Button({
//     className: 'calendar-header-button',
//     onClicked: () => {
//         if (calMonth.value == 0) {
//             calMonth.value = 11;
//             calYear.value--;
//         }
//         else calMonth.value--;
//     },
//     child: Label('')
// }),
// Button({
//     className: 'calendar-header-button',
//     onClicked: () => {
//         if (calMonth.value == 11) {
//             calMonth.value = 0;
//             calYear.value++;
//         }
//         else calMonth.value++;
//     },
//     child: Label('')
// })