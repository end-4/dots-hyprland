import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import PowerProfiles from "resource:///com/github/Aylur/ags/service/powerprofiles.js";
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, Entry, Icon, Label, Revealer, Scrollable, Slider, Stack, Overlay } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';

const PROFILES_META = {
    'power-saver': {
        'label': "Power Saver",
        'icon': "access_time",
        'describe': "Reduced performance and power usage",
    },
    'balanced': {
        'label': "Balanced",
        'icon': "balance",
        'describe': "Standard performance and power usage",
    },
    'performance': {
        'label': "Performance",
        'icon': "bolt",
        'describe': "High performance and power usage"
    },
};

/**
 * The item in the profile list
 * (Profile, CpuDriver, PlatformDriver, Driver)
 * @param {{[key: string]: string}} profile 
 */
const PowerProfile = (profile) => {
    const is_selected = () => PowerProfiles.active_profile == profile['Profile'];
    const meta = PROFILES_META[profile['Profile']];

    const profileName = Box({
        vertical: true,
        children: [
            Label ({
                hpack: 'start',
                label: meta.label
            }),
            Label ({
                hpack: 'start',
                className: 'txt-smaller txt-subtext',
                label: meta.describe
            })
        ],
    });

    return Button ({
        onClicked: is_selected() ? () => { } : () => { PowerProfiles.active_profile = profile['Profile']; },
        child: Box ({
            className: 'sidebar-wifinetworks-network spacing-h-10',
            children: [
                MaterialIcon (meta.icon, 'hugerass'),
                profileName,
                Box ({ hexpand: true }),
                is_selected() ? MaterialIcon('check', 'large') : null
            ],
        }),
    });
}

export default (props) => {
    const profile_list = Box ({
        vertical: true,
        className: 'spacing-v-10',
        children: [
            Overlay ({
                passThrough: true,
                child: Scrollable({
                    vexpand: true,
                    child: Box ({
                        vertical: true,
                        attribute: {
                            'updateProfiles': (self) => {
                                self.children = PowerProfiles.profiles.map(n => PowerProfile(n)).reverse();
                            },
                        },
                        className: 'spacing-v-5 margin-bottom-15',
                        setup: (self) => self.hook (PowerProfiles, self.attribute.updateProfiles),
                    }),
                }),
                overlays: [
                    Box({
                        className: 'sidebar-centermodules-scrollgradient-bottom'
                    }),
                ],
            }),
        ],
    });

    return Box ({
        ...props,
        className: 'spacing-v-10',
        vertical: true,
        children: [
            profile_list
        ],
    });
}