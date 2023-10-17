const { Gdk, Gtk } = imports.gi;
import { Utils, Widget } from '../imports.js';
import { MenuService } from "../scripts/menuservice.js";
const { execAsync, exec } = Utils;
const { Box, EventBox } = Widget;
import {
    ToggleIconBluetooth, ToggleIconWifi, HyprToggleIcon,
    ModuleEditIcon, ModuleSettingsIcon, ModulePowerIcon
} from "./quicktoggles.js";
import { ModuleMiscToggles, ModuleNightLight } from "./misctoggles.js";
import { ModuleNotificationList } from "./notificationlist.js";
import { ModuleMusicControls } from "./musiccontrols.js";
import { ModuleCalendar } from "./calendar.js";

export const SidebarRight = () => Box({
    vertical: true,
    children: [
        EventBox({
            onPrimaryClick: () => MenuService.close('sideright'),
            onSecondaryClick: () => MenuService.close('sideright'),
            onMiddleClick: () => MenuService.close('sideright'),
        }),
        Box({
            vertical: true,
            vexpand: true,
            className: 'sidebar-right sideright-hide',
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
                                    className: 'spacing-h-5 sidebar-group-invisible',
                                    children: [
                                        Widget.Label({
                                            className: 'txt-title-small txt',
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
                                        ModuleSettingsIcon({ halign: 'end' }),
                                        ModulePowerIcon({ halign: 'end' }),
                                    ]
                                }),
                                Box({
                                    className: 'sidebar-group spacing-h-10',
                                    children: [
                                        ToggleIconWifi({ hexpand: 'true' }),
                                        ToggleIconBluetooth({ hexpand: 'true' }),
                                        HyprToggleIcon('mouse', 'Raw input', 'input:force_no_accel', { hexpand: 'true' }),
                                        HyprToggleIcon('front_hand', 'No touchpad while typing', 'input:touchpad:disable_while_typing', { hexpand: 'true' }),
                                        ModuleNightLight({ hexpand: 'true' }),
                                    ]
                                }),
                            ]
                        }),
                        ModuleNotificationList({ vexpand: true, }),
                        ModuleCalendar(),
                    ]
                }),
            ],
            connections: [
                [MenuService, box => { // Hide anims when closing
                    box.toggleClassName('sideright-hide', !('sideright' === MenuService.opened));
                }],
                ['key-press-event', (box, event) => {
                    if (event.get_keyval()[1] === Gdk.KEY_Escape) {
                        MenuService.close('sideright');
                    }
                }]
            ],
        }),
    ]
});

