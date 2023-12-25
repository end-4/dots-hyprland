const { GLib, Gdk, Gtk } = imports.gi;
import { Utils, Widget } from '../../imports.js';
const { execAsync, exec } = Utils;
const { Box, EventBox } = Widget;
import {
    ToggleIconBluetooth,
    ToggleIconWifi,
    HyprToggleIcon,
    ModuleNightLight,
    ModuleInvertColors,
    ModuleIdleInhibitor,
    ModuleEditIcon,
    ModuleReloadIcon,
    ModuleSettingsIcon,
    ModulePowerIcon
} from "./quicktoggles.js";
import ModuleNotificationList from "./notificationlist.js";
import { ModuleCalendar } from "./calendar.js";

// const NUM_OF_TOGGLES_PER_LINE = 5;
// const togglesFlowBox = Widget.FlowBox({
//     className: 'sidebar-group spacing-h-10',
//     setup: (self) => {
//         self.set_max_children_per_line(NUM_OF_TOGGLES_PER_LINE);
//         self.add(ToggleIconWifi({ hexpand: true }));
//         self.add(ToggleIconBluetooth({ hexpand: true }));
//         self.add(HyprToggleIcon('mouse', 'Raw input', 'input:force_no_accel', { hexpand: true }));
//         self.add(HyprToggleIcon('front_hand', 'No touchpad while typing', 'input:touchpad:disable_while_typing', { hexpand: true }));
//         self.add(ModuleNightLight({ hexpand: true }));
//         // Setup flowbox rearrange
//         self.connect('child-activated', (self, child) => {
//             if (child.get_index() === 0) {
//                 self.reorder_child(child, self.get_children().length - 1);
//             } else {
//                 self.reorder_child(child, 0);
//             }
//         });
//     }
// })

const timeRow = Box({
    className: 'spacing-h-5 sidebar-group-invisible-morehorizpad',
    children: [
        // Widget.Label({
        //     className: 'txt-title txt',
        //     connections: [[5000, label => {
        //         label.label = GLib.DateTime.new_now_local().format("%H:%M");
        //     }]],
        // }),
        Widget.Label({
            hpack: 'center',
            className: 'txt-small txt',
            connections: [[5000, label => {
                execAsync(['bash', '-c', `uptime -p | sed -e 's/up //;s/ hours,/h/;s/ minutes/m/'`]).then(upTimeString => {
                    label.label = `System uptime: ${upTimeString}`;
                }).catch(print);
            }]],
        }),
        Widget.Box({ hexpand: true }),
        // ModuleEditIcon({ hpack: 'end' }), // TODO: Make this work
        ModuleReloadIcon({ hpack: 'end' }),
        ModuleSettingsIcon({ hpack: 'end' }),
        ModulePowerIcon({ hpack: 'end' }),
    ]
});

const togglesBox = Widget.Box({
    hpack: 'center',
    className: 'sidebar-togglesbox spacing-h-10',
    children: [
        ToggleIconWifi(),
        ToggleIconBluetooth(),
        HyprToggleIcon('mouse', 'Raw input', 'input:force_no_accel', {}),
        HyprToggleIcon('front_hand', 'No touchpad while typing', 'input:touchpad:disable_while_typing', {}),
        ModuleNightLight(),
        ModuleInvertColors(),
        ModuleIdleInhibitor(),
    ]
})

export default () => Box({
    vexpand: true,
    hexpand: true,
    children: [
        EventBox({
            onPrimaryClick: () => App.closeWindow('sideright'),
            onSecondaryClick: () => App.closeWindow('sideright'),
            onMiddleClick: () => App.closeWindow('sideright'),
        }),
        Box({
            vertical: true,
            vexpand: true,
            className: 'sidebar-right spacing-v-15',
            children: [
                Box({
                    vertical: true,
                    className: 'spacing-v-5',
                    children: [
                        timeRow,
                        // togglesFlowBox,
                        togglesBox,
                    ]
                }),
                ModuleNotificationList({ vexpand: true, }),
                ModuleCalendar(),
            ]
        }),
    ]
});
