// This file is for brightness/volume indicators
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
const { Box, Label, ProgressBar } = Widget;
import { MarginRevealer } from '../.widgethacks/advancedrevealers.js';
import Brightness from '../../services/brightness.js';
import Indicator from '../../services/indicator.js';

const OsdValue = ({ name, nameSetup = undefined, labelSetup, progressSetup, ...rest }) => {
    const valueName = Label({
        xalign: 0, yalign: 0, hexpand: true,
        className: 'osd-label',
        label: `${name}`,
        setup: nameSetup,
    });
    const valueNumber = Label({
        hexpand: false, className: 'osd-value-txt',
        setup: labelSetup,
    });
    return Box({ // Volume
        vertical: true,
        hexpand: true,
        className: 'osd-bg osd-value',
        attribute: {
            'disable': () => {
                valueNumber.label = '󰖭';
            }
        },
        children: [
            Box({
                vexpand: true,
                children: [
                    valueName,
                    valueNumber,
                ]
            }),
            ProgressBar({
                className: 'osd-progress',
                hexpand: true,
                vertical: false,
                setup: progressSetup,
            })
        ],
        ...rest,
    });
}

export default () => {
    const brightnessIndicator = OsdValue({
        name: 'Brightness',
        labelSetup: (self) => self.hook(Brightness, self => {
            self.label = `${Math.round(Brightness.screen_value * 100)}`;
        }, 'notify::screen-value'),
        progressSetup: (self) => self.hook(Brightness, (progress) => {
            const updateValue = Brightness.screen_value;
            progress.value = updateValue;
        }, 'notify::screen-value'),
    });

    const volumeIndicator = OsdValue({
        name: 'Volume',
        attribute: {
            headphones: undefined,
        },
        nameSetup: (self) => Utils.timeout(1, () => {
            const updateAudioDevice = (self) => {
                const usingHeadphones = (Audio.speaker?.stream?.port)?.includes('Headphones');
                if (volumeIndicator.attribute.headphones === undefined ||
                    volumeIndicator.attribute.headphones !== usingHeadphones) {
                    volumeIndicator.attribute.headphones = usingHeadphones;
                    self.label = usingHeadphones ? 'Headphones' : 'Speakers';
                    Indicator.popup(1);
                }
            }
            self.hook(Audio, updateAudioDevice);
            Utils.timeout(1000, updateAudioDevice);
        }),
        labelSetup: (self) => self.hook(Audio, (label) => {
            label.label = `${Math.round(Audio.speaker?.volume * 100)}`;
        }),
        progressSetup: (self) => self.hook(Audio, (progress) => {
            const updateValue = Audio.speaker?.volume;
            if (!isNaN(updateValue)) progress.value = updateValue;
        }),
    });
    return MarginRevealer({
        transition: 'slide_down',
        showClass: 'osd-show',
        hideClass: 'osd-hide',
        extraSetup: (self) => self
            .hook(Indicator, (revealer, value) => {
                if (value > -1) revealer.attribute.show();
                else revealer.attribute.hide();
            }, 'popup')
        ,
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
}