// This file is for brightness/volume indicators
const { GLib, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../../imports.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
import Notifications from 'resource:///com/github/Aylur/ags/service/notifications.js';
const { Box, EventBox, Icon, Scrollable, Label, Button, Revealer } = Widget;
import Brightness from '../../scripts/brightness.js';
import Indicator from '../../scripts/indicator.js';
import Notification from '../../lib/notification.js';

const OsdValue = (name, labelConnections, progressConnections, props = {}) => Widget.Box({ // Volume
    ...props,
    vertical: true,
    className: 'osd-bg osd-value',
    hexpand: true,
    children: [
        Widget.Box({
            vexpand: true,
            children: [
                Widget.Label({
                    xalign: 0, yalign: 0, hexpand: true,
                    className: 'osd-label',
                    label: `${name}`,
                }),
                Widget.Label({
                    hexpand: false, className: 'osd-value-txt',
                    label: '100',
                    connections: labelConnections,
                }),
            ]
        }),
        Widget.ProgressBar({
            className: 'osd-progress',
            hexpand: true,
            vertical: false,
            connections: progressConnections,
        })
    ],
});

const brightnessIndicator = OsdValue('Brightness',
    [[Brightness, self => {
        self.label = `${Math.round(Brightness.screen_value * 100)}`;
    }, 'notify::screen-value']],
    [[Brightness, (progress) => {
        const updateValue = Brightness.screen_value;
        progress.value = updateValue;
    }, 'notify::screen-value']],
)

const volumeIndicator = OsdValue('Volume',
    [[Audio, (label) => {
        label.label = `${Math.round(Audio.speaker?.volume * 100)}`;
    }]],
    [[Audio, (progress) => {
        const updateValue = Audio.speaker?.volume;
        if (!isNaN(updateValue)) progress.value = updateValue;
    }]],
);

export default () => Widget.Revealer({
    transition: 'slide_down',
    connections: [
        [Indicator, (revealer, value) => {
            revealer.revealChild = (value > -1);
        }, 'popup'],
    ],
    child: Widget.Box({
        hpack: 'center',
        vertical: false,
        children: [
            brightnessIndicator,
            volumeIndicator,
        ]
    })
});