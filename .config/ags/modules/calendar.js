const { Gio, Gdk, Gtk } = imports.gi;
import { App, Widget, Utils } from '../imports.js';
const { Box, CenterBox, Label, Button } = Widget;
import { MaterialIcon } from "./lib/materialicon.js";
import { getCalendarLayout } from "../scripts/calendarlayout.js";
import { setupCursorHover } from "./lib/cursorhover.js";

let calendarJson = getCalendarLayout(undefined, true);
let monthshift = 0;

function fileExists(filePath) {
    let file = Gio.File.new_for_path(filePath);
    return file.query_exists(null);
}
// export let todoJson = JSON.parse(Utils.readFile(`${App.configDir}/../../.cache/ags/user/todo.json`));
// actually we have to check if the file exists first, create it if not
export let todoJson = undefined;
if (fileExists(`${App.configDir}/../../.cache/ags/user/todo.json`)) {
    todoJson = JSON.parse(Utils.readFile(`${App.configDir}/../../.cache/ags/user/todo.json`));
}
else {
    todoJson = [];
    Utils.writeFile(JSON.stringify(todoJson), `${App.configDir}/../../.cache/ags/user/todo.json`)
        .catch(err => print(err));
}

function getDateInXMonthsTime(x) {
    var currentDate = new Date(); // Get the current date
    var targetMonth = currentDate.getMonth() + x; // Calculate the target month
    var targetYear = currentDate.getFullYear(); // Get the current year

    // Adjust the year and month if necessary
    targetYear += Math.floor(targetMonth / 12);
    targetMonth = (targetMonth % 12 + 12) % 12;

    // Create a new date object with the target year and month
    var targetDate = new Date(targetYear, targetMonth, 1);

    // Set the day to the last day of the month to get the desired date
    // targetDate.setDate(0);

    return targetDate;
}

const weekDays = [ // stupid stupid stupid!! how tf is Sunday the first day of the week??
    { day: 'Su', today: 0 },
    { day: 'Mo', today: 0 },
    { day: 'Tu', today: 0 },
    { day: 'We', today: 0 },
    { day: 'Th', today: 0 },
    { day: 'Fr', today: 0 },
    { day: 'Sa', today: 0 },
]

const CalendarDay = (day, today) => Widget.Button({
    className: `sidebar-calendar-btn ${today == 1 ? 'sidebar-calendar-btn-today' : (today == -1 ? 'sidebar-calendar-btn-othermonth' : '')}`,
    child: Widget.Overlay({
        child: Box({}),
        overlays: [Label({
            halign: 'center',
            className: 'txt-smallie txt-semibold sidebar-calendar-btn-txt',
            label: String(day),
        })],
    })
})

const CalendarWidget = () => {
    const calendarMonthYear = Widget.Button({
        className: 'txt txt-large sidebar-calendar-monthyear-btn',
        onPrimaryClick: () => shiftCalendarXMonths(0),
        setup: (button) => {
            button.label = `${new Date().toLocaleString('default', { month: 'long' })} ${new Date().getFullYear()}`;
            setupCursorHover(button);
        }
    });
    const addCalendarChildren = (box, calendarJson) => {
        box.children = calendarJson.map((row, i) => Widget.Box({
            // homogeneous: true,
            className: 'spacing-h-5',
            children: row.map((day, i) =>
                CalendarDay(day.day, day.today)
            )
        }))
    }
    function shiftCalendarXMonths(x) {
        if (x == 0)
            monthshift = 0;
        else
            monthshift += x;
        var newDate = undefined;
        if (monthshift == 0)
            newDate = new Date();
        else
            newDate = getDateInXMonthsTime(monthshift);
        calendarJson = getCalendarLayout(newDate, monthshift == 0);
        calendarMonthYear.label = `${monthshift == 0 ? '' : '• '}${newDate.toLocaleString('default', { month: 'long' })} ${newDate.getFullYear()}`;
        addCalendarChildren(calendarDays, calendarJson);
    }
    const calendarHeader = Widget.Box({
        className: 'spacing-h-5 sidebar-calendar-header',
        setup: (box) => {
            box.pack_start(calendarMonthYear, false, false, 0);
            box.pack_end(Widget.Box({
                className: 'spacing-h-5',
                children: [
                    Button({
                        className: 'sidebar-calendar-monthshift-btn',
                        onClicked: () => shiftCalendarXMonths(-1),
                        child: MaterialIcon('chevron_left', 'norm'),
                        setup: (button) => setupCursorHover(button),
                    }),
                    Button({
                        className: 'sidebar-calendar-monthshift-btn',
                        onClicked: () => shiftCalendarXMonths(1),
                        child: MaterialIcon('chevron_right', 'norm'),
                        setup: (button) => setupCursorHover(button),
                    })
                ]
            }), false, false, 0);
        }
    })
    const calendarDays = Widget.Box({
        hexpand: true,
        vertical: true,
        className: 'spacing-v-5',
        setup: (box) => {
            addCalendarChildren(box, calendarJson);
        }
    });
    return Widget.EventBox({
        onScrollUp: () => shiftCalendarXMonths(-1),
        onScrollDown: () => shiftCalendarXMonths(1),
        child: Widget.Box({
            halign: 'center',
            children: [
                Widget.Box({
                    hexpand: true,
                    vertical: true,
                    className: 'spacing-v-5',
                    children: [
                        calendarHeader,
                        Widget.Box({
                            homogeneous: true,
                            className: 'spacing-h-5',
                            children: weekDays.map((day, i) => CalendarDay(day.day, day.today))
                        }),
                        calendarDays,
                    ]
                })
            ]
        })
    });
};

const defaultTodoSelected = 'undone';

function updateItemLists() {
    undoneItems.children = drawTodoItems(todoJson, false);
    doneItems.children = drawTodoItems(todoJson, true);
    todoItemsBox.items = [
        ['undone', undoneItems],
        ['done', doneItems],
    ];
}
const drawTodoItems = (todoJson, isDone) => todoJson.map((task, i) => {
    if (task.done != isDone) return null;
    return Widget.Box({
        className: 'spacing-h-5',
        children: [
            Widget.Label({
                className: 'txt txt-small',
                label: '•',
            }),
            Widget.Label({
                hexpand: true,
                xalign: 0,
                wrap: true,
                className: 'txt txt-small sidebar-todo-txt',
                label: task.content,
            }),
            Widget.Button({
                valign: 'center',
                className: 'txt sidebar-todo-item-action',
                child: MaterialIcon(`${isDone ? 'remove_done' : 'check'}`, 'norm', { valign: 'center' }),
                onPrimaryClick: () => {
                    todoItemsBox.shown = defaultTodoSelected;
                    if (isDone)
                        uncheckedTodoItems(i);
                    else
                        checkTodoItem(i);
                    updateItemLists();
                },
                setup: (button) => setupCursorHover(button),
            }),
            Widget.Button({
                valign: 'center',
                className: 'txt sidebar-todo-item-action',
                child: MaterialIcon('delete_forever', 'norm', { valign: 'center' }),
                onPrimaryClick: () => {
                    removeTodoItem(i);
                    updateItemLists();
                },
                setup: (button) => setupCursorHover(button),
            }),
        ]
    });
});
const undoneItems = Widget.Scrollable({
    valign: 'fill',
    child: Widget.Box({
        vertical: true, children: drawTodoItems(todoJson, false)
    }),
});
const doneItems = Widget.Scrollable({
    child: Widget.Box({
        vertical: true, children: drawTodoItems(todoJson, true)
    }),
});

const todoItemsBox = Widget.Stack({
    valign: 'fill',
    transition: 'slide_left_right',
    items: [
        ['undone', undoneItems],
        ['done', doneItems],
    ],
});

const TodoWidget = () => {

    return Widget.Box({
        hexpand: true,
        vertical: true,
        className: 'spacing-v-10',
        setup: (box) => {
            // undone/done selector rail
            box.pack_start(Widget.Box({
                className: 'sidebar-todo-selector-rail spacing-h-5',
                homogeneous: true,
                setup: (box) => {
                    const undoneButton = Widget.Button({
                        hexpand: true,
                        className: 'sidebar-todo-selector-tab',
                        onPrimaryClick: (button) => {
                            todoItemsBox.shown = 'undone';
                            button.toggleClassName('sidebar-todo-selector-tab-active', true);
                            doneButton.toggleClassName('sidebar-todo-selector-tab-active', false);
                        },
                        child: Box({
                            halign: 'center',
                            vertical: true,
                            children: [
                                MaterialIcon('format_list_bulleted', 'larger'),
                                Label({
                                    className: 'txt txt-smallie',
                                    label: 'Unfinished',
                                })
                            ]
                        }),
                        setup: (button) => {
                            button.toggleClassName('sidebar-todo-selector-tab-active', defaultTodoSelected === 'undone');
                            setupCursorHover(button);
                        },
                    });
                    const doneButton = Widget.Button({
                        hexpand: true,
                        className: 'sidebar-todo-selector-tab',
                        onPrimaryClick: (button) => {
                            todoItemsBox.shown = 'done';
                            button.toggleClassName('sidebar-todo-selector-tab-active', true);
                            undoneButton.toggleClassName('sidebar-todo-selector-tab-active', false);
                        },
                        child: Box({
                            halign: 'center',
                            vertical: true,
                            children: [
                                MaterialIcon('task_alt', 'larger'),
                                Label({
                                    className: 'txt txt-smallie',
                                    label: 'Done',
                                })
                            ]
                        }),
                        setup: (button) => {
                            button.toggleClassName('sidebar-todo-selector-tab-active', defaultTodoSelected === 'done')
                            setupCursorHover(button);
                        },
                    });
                    box.pack_start(undoneButton, false, true, 0);
                    box.pack_start(doneButton, false, true, 0);
                }
            }), false, false, 0);
            box.pack_end(todoItemsBox, true, true, 0);
        }
    });
};

export function addTodoItem(content) {
    todoJson.push({ content, done: false });
    Utils.writeFile(JSON.stringify(todoJson), `${App.configDir}/../../.cache/ags/user/todo.json`)
        .catch(err => print(err));
    updateItemLists();
}

export function checkTodoItem(index) {
    todoJson[index].done = true;
    Utils.writeFile(JSON.stringify(todoJson), `${App.configDir}/../../.cache/ags/user/todo.json`)
        .catch(err => print(err));
    updateItemLists();
}

export function uncheckedTodoItems(index) {
    todoJson[index].done = false;
    Utils.writeFile(JSON.stringify(todoJson), `${App.configDir}/../../.cache/ags/user/todo.json`)
        .catch(err => print(err));
    updateItemLists();
}

export function removeTodoItem(index) {
    todoJson.splice(index, 1);
    Utils.writeFile(JSON.stringify(todoJson), `${App.configDir}/../../.cache/ags/user/todo.json`)
        .catch(err => print(err));
    updateItemLists();
}

const defaultShown = 'calendar';
const contentStack = Widget.Stack({
    hexpand: true,
    items: [
        ['calendar', CalendarWidget()],
        ['todo', TodoWidget()],
        // ['stars', Widget.Label({ label: 'GitHub feed will be here' })],
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
            Label({
                className: `txt icon-material txt-hugeass`,
                label: icon,
            }),
            Label({
                label: name,
                className: 'txt txt-smallie',
            }),
        ]
    }),
    setup: (button) => {
        button.toggleClassName('sidebar-navrail-btn-active', defaultShown === stackItemName);
        setupCursorHover(button);
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
                // StackButton(box, 'stars', 'star', 'GitHub'),
            ]
        }), false, false, 0);
        // ags.Widget({ // TDOO: replace this sad default calendar with a custom one
        //     type: imports.gi.Gtk.Calendar,
        // }),
        box.pack_end(contentStack, false, false, 0);
    }
})
