// This file is for brightness/volume indicators
const { GLib, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../../imports.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
const { Box, Label, ProgressBar, Revealer } = Widget;
import { MarginRevealer } from '../../lib/advancedwidgets.js';
import Brightness from '../../services/brightness.js';
import Indicator from '../../services/indicator.js';

const OsdValue = (name, labelConnections, progressConnections, props = {}) => Box({ // Volume
    ...props,
    vertical: true,
    className: 'osd-bg osd-value',
    hexpand: true,
    children: [
        Box({
            vexpand: true,
            children: [
                Label({
                    xalign: 0, yalign: 0, hexpand: true,
                    className: 'osd-label',
                    label: `${name}`,
                }),
                Label({
                    hexpand: false, className: 'osd-value-txt',
                    label: '100',
                    connections: labelConnections,
                }),
            ]
        }),
        ProgressBar({
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

export default () => MarginRevealer({
    transition: 'slide_down',
    showClass: 'osd-show',
    hideClass: 'osd-hide',
    connections: [
        [Indicator, (revealer, value) => {
            if(value > -1) revealer._show();
            else revealer._hide();
        }, 'popup'],
    ],
    child: Box({
        hpack: 'center',
        vertical: false,
        className: 'spacing-h--10',
        children: [
            brightnessIndicator,
            volumeIndicator,
        ]
    })
});