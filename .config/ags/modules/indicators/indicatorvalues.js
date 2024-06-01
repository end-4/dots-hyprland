// This file is for brightness/volume indicators
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
const { Box, Label, ProgressBar } = Widget;
import { MarginRevealer } from '../.widgethacks/advancedrevealers.js';
import Brightness from '../../services/brightness.js';
import Indicator from '../../services/indicator.js';

const OsdValue = ({
    name, nameSetup = undefined, labelSetup, progressSetup,
    extraClassName = '', extraProgressClassName = '',
    ...rest
}) => {
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
        className: `osd-bg osd-value ${extraClassName}`,
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
                className: `osd-progress ${extraProgressClassName}`,
                hexpand: true,
                vertical: false,
                setup: progressSetup,
            })
        ],
        ...rest,
    });
}

export default (monitor = 0) => {
    const brightnessIndicator = OsdValue({
        name: 'Brightness',
        extraClassName: 'osd-brightness',
        extraProgressClassName: 'osd-brightness-progress',
        labelSetup: (self) => self.hook(Brightness[monitor], self => {
            self.label = `${Math.round(Brightness[monitor].screen_value * 100)}`;
        }, 'notify::screen-value'),
        progressSetup: (self) => self.hook(Brightness[monitor], (progress) => {
            const updateValue = Brightness[monitor].screen_value;
            if (updateValue !== progress.value) Indicator.popup(1);
            progress.value = updateValue;
        }, 'notify::screen-value'),
    });

    const volumeIndicator = OsdValue({
        name: 'Volume',
        extraClassName: 'osd-volume',
        extraProgressClassName: 'osd-volume-progress',
        attribute: { headphones: undefined , device: undefined},
        nameSetup: (self) => Utils.timeout(1, () => {
            const updateAudioDevice = (self) => {
                const usingHeadphones = (Audio.speaker?.stream?.port)?.toLowerCase().includes('headphone');
                if (volumeIndicator.attribute.headphones === undefined ||
                    volumeIndicator.attribute.headphones !== usingHeadphones) {
                    volumeIndicator.attribute.headphones = usingHeadphones;
                    self.label = usingHeadphones ? 'Headphones' : 'Speakers';
                    // Indicator.popup(1);
                }
            }
            self.hook(Audio, updateAudioDevice);
            Utils.timeout(1000, updateAudioDevice);
        }),
        labelSetup: (self) => self.hook(Audio, (label) => {
            const newDevice = (Audio.speaker?.name);
            const updateValue = Math.round(Audio.speaker?.volume * 100);
            if (!isNaN(updateValue)) {
                if (newDevice === volumeIndicator.attribute.device && updateValue != label.label) {
                    Indicator.popup(1);
                }
            }
            volumeIndicator.attribute.device = newDevice;
            label.label = `${updateValue}`;
        }),
        progressSetup: (self) => self.hook(Audio, (progress) => {
            const updateValue = Audio.speaker?.volume;
            if (!isNaN(updateValue)) {
                if (updateValue > 1) progress.value = 1;
                else progress.value = updateValue;
            }
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
