import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, Label, Revealer } = Widget;
import { MaterialIcon } from "../../lib/materialicon.js";
import Todo from "../../services/todo.js";
import { setupCursorHover } from "../../lib/cursorhover.js";
import { NavigationIndicator } from "../../lib/navigationindicator.js";

const defaultTodoSelected = 'undone';

const todoListItem = (task, id, isDone, isEven = false) => {
    const crosser = Widget.Box({
        className: 'sidebar-todo-crosser',
    });
    const todoContent = Widget.Box({
        className: 'sidebar-todo-item spacing-h-5',
        children: [
            Widget.Label({
                hexpand: true,
                xalign: 0,
                wrap: true,
                className: 'txt txt-small sidebar-todo-txt',
                label: task.content,
                selectable: true,
            }),
            Widget.Button({ // Check/Uncheck
                vpack: 'center',
                className: 'txt sidebar-todo-item-action',
                child: MaterialIcon(`${isDone ? 'remove_done' : 'check'}`, 'norm', { vpack: 'center' }),
                onClicked: (self) => {
                    const contentWidth = todoContent.get_allocated_width();
                    crosser.toggleClassName('sidebar-todo-crosser-crossed', true);
                    crosser.css = `margin-left: -${contentWidth}px;`;
                    Utils.timeout(200, () => {
                        widgetRevealer.revealChild = false;
                    })
                    Utils.timeout(350, () => {
                        if (isDone)
                            Todo.uncheck(id);
                        else
                            Todo.check(id);
                    })
                },
                setup: setupCursorHover,
            }),
            Widget.Button({ // Remove
                vpack: 'center',
                className: 'txt sidebar-todo-item-action',
                child: MaterialIcon('delete_forever', 'norm', { vpack: 'center' }),
                onClicked: () => {
                    const contentWidth = todoContent.get_allocated_width();
                    crosser.toggleClassName('sidebar-todo-crosser-removed', true);
                    crosser.css = `margin-left: -${contentWidth}px;`;
                    Utils.timeout(200, () => {
                        widgetRevealer.revealChild = false;
                    })
                    Utils.timeout(350, () => {
                        Todo.remove(id);
                    })
                },
                setup: setupCursorHover,
            }),
            crosser,
        ]
    });
    const widgetRevealer = Widget.Revealer({
        revealChild: true,
        transition: 'slide_down',
        transitionDuration: 150,
        child: todoContent,
    })
    return widgetRevealer;
}

const todoItems = (isDone) => Widget.Scrollable({
    hscroll: 'never',
    vscroll: 'automatic',
    child: Widget.Box({
        vertical: true,
        setup: (self) => self
            .hook(Todo, (self) => {
                self.children = Todo.todo_json.map((task, i) => {
                    if (task.done != isDone) return null;
                    return todoListItem(task, i, isDone);
                })
                if (self.children.length == 0) {
                    self.homogeneous = true;
                    self.children = [
                        Widget.Box({
                            hexpand: true,
                            vertical: true,
                            vpack: 'center',
                            className: 'txt',
                            children: [
                                MaterialIcon(`${isDone ? 'checklist' : 'check_circle'}`, 'gigantic'),
                                Label({ label: `${isDone ? 'Finished tasks will go here' : 'Nothing here!'}` })
                            ]
                        })
                    ]
                }
                else self.homogeneous = false;
            }, 'updated')
        ,
    }),
    setup: (listContents) => {
        const vScrollbar = listContents.get_vscrollbar();
        vScrollbar.get_style_context().add_class('sidebar-scrollbar');
    }
});

const UndoneTodoList = () => {
    const newTaskButton = Revealer({
        transition: 'slide_left',
        transitionDuration: 200,
        revealChild: true,
        child: Button({
            className: 'txt-small sidebar-todo-new',
            halign: 'end',
            vpack: 'center',
            label: '+ New task',
            setup: setupCursorHover,
            onClicked: (self) => {
                newTaskButton.revealChild = false;
                newTaskEntryRevealer.revealChild = true;
                confirmAddTask.revealChild = true;
                cancelAddTask.revealChild = true;
                newTaskEntry.grab_focus();
            }
        })
    });
    const cancelAddTask = Revealer({
        transition: 'slide_right',
        transitionDuration: 200,
        revealChild: false,
        child: Button({
            className: 'txt-norm icon-material sidebar-todo-add',
            halign: 'end',
            vpack: 'center',
            label: 'close',
            setup: setupCursorHover,
            onClicked: (self) => {
                newTaskEntryRevealer.revealChild = false;
                confirmAddTask.revealChild = false;
                cancelAddTask.revealChild = false;
                newTaskButton.revealChild = true;
                newTaskEntry.text = '';
            }
        })
    });
    const newTaskEntry = Widget.Entry({
        // hexpand: true,
        vpack: 'center',
        className: 'txt-small sidebar-todo-entry',
        placeholderText: 'Add a task...',
        onAccept: ({ text }) => {
            if (text == '') return;
            Todo.add(text)
            newTaskEntry.text = '';
        },
        onChange: ({ text }) => confirmAddTask.child.toggleClassName('sidebar-todo-add-available', text != ''),
    });
    const newTaskEntryRevealer = Revealer({
        transition: 'slide_right',
        transitionDuration: 200,
        revealChild: false,
        child: newTaskEntry,
    });
    const confirmAddTask = Revealer({
        transition: 'slide_right',
        transitionDuration: 200,
        revealChild: false,
        child: Button({
            className: 'txt-norm icon-material sidebar-todo-add',
            halign: 'end',
            vpack: 'center',
            label: 'arrow_upward',
            setup: setupCursorHover,
            onClicked: (self) => {
                if (newTaskEntry.text == '') return;
                Todo.add(newTaskEntry.text);
                newTaskEntry.text = '';
            }
        })
    });
    return Box({ // The list, with a New button
        vertical: true,
        className: 'spacing-v-5',
        setup: (box) => {
            box.pack_start(todoItems(false), true, true, 0);
            box.pack_start(Box({
                setup: (self) => {
                    self.pack_start(cancelAddTask, false, false, 0);
                    self.pack_start(newTaskEntryRevealer, true, true, 0);
                    self.pack_start(confirmAddTask, false, false, 0);
                    self.pack_start(newTaskButton, false, false, 0);
                }
            }), false, false, 0);
        },
    });
}

const todoItemsBox = Widget.Stack({
    vpack: 'fill',
    transition: 'slide_left_right',
    children: {
        'undone': UndoneTodoList(),
        'done': todoItems(true),
    },
});

export const TodoWidget = () => {
    const TodoTabButton = (isDone, navIndex) => Widget.Button({
        hexpand: true,
        className: 'sidebar-selector-tab',
        onClicked: (button) => {
            todoItemsBox.shown = `${isDone ? 'done' : 'undone'}`;
            const kids = button.get_parent().get_children();
            for (let i = 0; i < kids.length; i++) {
                if (kids[i] != button) kids[i].toggleClassName('sidebar-selector-tab-active', false);
                else button.toggleClassName('sidebar-selector-tab-active', true);
            }
            // Fancy highlighter line width
            const buttonWidth = button.get_allocated_width();
            const highlightWidth = button.get_children()[0].get_allocated_width();
            navIndicator.css = `
                font-size: ${navIndex}px; 
                padding: 0px ${(buttonWidth - highlightWidth) / 2}px;
            `;
        },
        child: Box({
            hpack: 'center',
            className: 'spacing-h-5',
            children: [
                MaterialIcon(`${isDone ? 'task_alt' : 'format_list_bulleted'}`, 'larger'),
                Label({
                    className: 'txt txt-smallie',
                    label: `${isDone ? 'Done' : 'Unfinished'}`,
                })
            ]
        }),
        setup: (button) => Utils.timeout(1, () => {
            setupCursorHover(button);
            button.toggleClassName('sidebar-selector-tab-active', defaultTodoSelected === `${isDone ? 'done' : 'undone'}`);
        }),
    });
    const undoneButton = TodoTabButton(false, 0);
    const doneButton = TodoTabButton(true, 1);
    const navIndicator = NavigationIndicator(2, false, { // The line thing
        className: 'sidebar-selector-highlight',
        css: 'font-size: 0px; padding: 0rem 1.636rem;', // Shush
    })
    return Widget.Box({
        hexpand: true,
        vertical: true,
        className: 'spacing-v-10',
        setup: (box) => {     // undone/done selector rail
            box.pack_start(Widget.Box({
                vertical: true,
                children: [
                    Widget.Box({
                        className: 'sidebar-selectors spacing-h-5',
                        homogeneous: true,
                        setup: (box) => {
                            box.pack_start(undoneButton, false, true, 0);
                            box.pack_start(doneButton, false, true, 0);
                        }
                    }),
                    Widget.Box({
                        className: 'sidebar-selector-highlight-offset',
                        homogeneous: true,
                        children: [navIndicator]
                    })
                ]
            }), false, false, 0);
            box.pack_end(todoItemsBox, true, true, 0);
        },
    });
};

