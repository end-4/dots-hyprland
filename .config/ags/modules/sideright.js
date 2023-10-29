const { Gdk, Gtk } = imports.gi;
import { Utils, Widget } from '../imports.js';
const { execAsync, exec } = Utils;
const { Box, EventBox } = Widget;
import {
    ToggleIconBluetooth, ToggleIconWifi, HyprToggleIcon, ModuleNightLight,
    ModuleEditIcon, ModuleReloadIcon, ModuleSettingsIcon, ModulePowerIcon
} from "./quicktoggles.js";
import ModuleNotificationList from "./notificationlist.js";
import { ModuleMusicControls } from "./musiccontrols.js";
import { ModuleCalendar } from "./calendar.js";

const NUM_OF_TOGGLES_PER_LINE = 5;

const togglesFlowBox = Widget({
    type: Gtk.FlowBox,
    className: 'sidebar-group spacing-h-10',
    setup: (self) => {
        self.set_max_children_per_line(NUM_OF_TOGGLES_PER_LINE);
        self.add(ToggleIconWifi({ hexpand: 'true' }));
        self.add(ToggleIconBluetooth({ hexpand: 'true' }));
        self.add(HyprToggleIcon('mouse', 'Raw input', 'input:force_no_accel', { hexpand: 'true' }));
        self.add(HyprToggleIcon('front_hand', 'No touchpad while typing', 'input:touchpad:disable_while_typing', { hexpand: 'true' }));
        self.add(ModuleNightLight({ hexpand: 'true' }));
        // Setup flowbox rearrange
        self.connect('child-activated', (self, child) => {
            if (child.get_index() === 0) {
                self.reorder_child(child, self.get_children().length - 1);
            } else {
                self.reorder_child(child, 0);
            }
        });
    }
})

const togglesBox = Widget.Box({
    className: 'sidebar-group spacing-h-10',
    children: [
        ToggleIconWifi({ hexpand: 'true' }),
        ToggleIconBluetooth({ hexpand: 'true' }),
        HyprToggleIcon('mouse', 'Raw input', 'input:force_no_accel', { hexpand: 'true' }),
        HyprToggleIcon('front_hand', 'No touchpad while typing', 'input:touchpad:disable_while_typing', { hexpand: 'true' }),
        ModuleNightLight({ hexpand: 'true' }),
    ]
})

export default () => Box({
    // vertical: true,
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
            className: 'sidebar-right',
            children: [
                Box({
                    vertical: true,
                    vexpand: true,
                    className: 'spacing-v-15',
                    children: [
                        Box({
                            vertical: true,
                            className: 'spacing-v-5',
                            children: [
                                Box({ // Header
                                    className: 'spacing-h-5 sidebar-group-invisible-morehorizpad',
                                    children: [
                                        Widget.Label({
                                            className: 'txt-title txt',
                                            connections: [[5000, label => {
                                                execAsync([`date`, "+%H:%M"]).then(timeString => {
                                                    label.label = timeString;
                                                }).catch(print);
                                            }]],
                                        }),
                                        Widget.Label({
                                            halign: 'center',
                                            className: 'txt-small txt',
                                            connections: [[5000, label => {
                                                execAsync(['bash', '-c', `uptime -p | sed -e 's/up //;s/ hours,/h/;s/ minutes/m/'`]).then(upTimeString => {
                                                    label.label = `• uptime ${upTimeString}`;
                                                }).catch(print);
                                            }]],
                                        }),
                                        Widget.Box({ hexpand: true }),
                                        // ModuleEditIcon({ halign: 'end' }), // TODO: Make this work
                                        ModuleReloadIcon({ halign: 'end' }),
                                        ModuleSettingsIcon({ halign: 'end' }),
                                        ModulePowerIcon({ halign: 'end' }),
                                    ]
                                }),
                                // togglesFlowBox,
                                togglesBox,
                            ]
                        }),
                        ModuleNotificationList({ vexpand: true, }),
                        ModuleCalendar(),
                    ]
                }),
            ],
        }),
    ]
});
