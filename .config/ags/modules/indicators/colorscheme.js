const { Gio, GLib } = imports.gi;
import Variable from 'resource:///com/github/Aylur/ags/variable.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { ConfigToggle, ConfigMulipleSelection } from '../.commonwidgets/configwidgets.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { execAsync } = Utils;
import { setupCursorHover } from '../.widgetutils/cursorhover.js';
import { showColorScheme } from '../../variables.js';
import { MaterialIcon } from '../.commonwidgets/materialicon.js';
import { darkMode } from '../.miscutils/system.js';

const ColorBox = ({
    name = 'Color',
    ...rest
}) => Widget.Box({
    ...rest,
    homogeneous: true,
    children: [
        Widget.Label({
            label: `${name}`,
        })
    ]
})

const ColorSchemeSettingsRevealer = () => {
    const headerButtonIcon = MaterialIcon('expand_more', 'norm');
    const header = Widget.Button({
        className: 'osd-settings-btn-arrow',
        onClicked: () => {
            content.revealChild = !content.revealChild;
            headerButtonIcon.label = content.revealChild ? 'expand_less' : 'expand_more';
        },
        setup: setupCursorHover,
        hpack: 'end',
        child: headerButtonIcon,
    });
    const content = Widget.Revealer({
        revealChild: false,
        transition: 'slide_down',
        transitionDuration: 200,
        child: ColorSchemeSettings(),
        setup: (self) => self.hook(isHoveredColorschemeSettings, (revealer) => {
            if (isHoveredColorschemeSettings.value == false) {
                setTimeout(() => {
                    if (isHoveredColorschemeSettings.value == false)
                        revealer.revealChild = false;
                    headerButtonIcon.label = 'expand_more';
                }, 1500);
            }
        }),
    });
    return Widget.EventBox({
        onHover: (self) => {
            isHoveredColorschemeSettings.setValue(true);
        },
        onHoverLost: (self) => {
            isHoveredColorschemeSettings.setValue(false);
        },
        child: Widget.Box({
            vertical: true,
            children: [
                header,
                content,
            ]
        }),
    });
}

function calculateSchemeInitIndex(optionsArr, searchValue = 'vibrant') {
    if (searchValue == '')
        searchValue = 'vibrant';
    const flatArray = optionsArr.flatMap(subArray => subArray);
    const result = flatArray.findIndex(element => element.value === searchValue);
    const rowIndex = Math.floor(result / optionsArr[0].length);
    const columnIndex = result % optionsArr[0].length;
    return [rowIndex, columnIndex];
}

const schemeOptionsArr = [
    [
        { name: 'Tonal Spot', value: 'tonalspot' },
        { name: 'Fruit Salad', value: 'fruitsalad' },
        { name: 'Fidelity', value: 'fidelity' },
        { name: 'Rainbow', value: 'rainbow' },
    ],
    [
        { name: 'Neutral', value: 'neutral' },
        { name: 'Monochrome', value: 'monochrome' },
        { name: 'Expressive', value: 'expressive' },
        { name: 'Vibrant', value: 'vibrant' },
    ],
    [
        { name: 'Vibrant+', value: 'morevibrant' },
    ],
    //[
    //  { name: 'Content', value: 'content' },
    //]
];

const LIGHTDARK_FILE_LOCATION = `${GLib.get_user_state_dir()}/ags/user/colormode.txt`;
const initTransparency = Utils.exec(`bash -c "sed -n \'2p\' ${LIGHTDARK_FILE_LOCATION}"`);
const initTransparencyVal = (initTransparency == "transparent") ? 1 : 0;
const initScheme = Utils.exec(`bash -c "sed -n \'3p\' ${LIGHTDARK_FILE_LOCATION}"`);
const initSchemeIndex = calculateSchemeInitIndex(schemeOptionsArr, initScheme);

const ColorSchemeSettings = () => Widget.Box({
    className: 'osd-colorscheme-settings spacing-v-5 margin-20',
    vertical: true,
    vpack: 'center',
    children: [
        Widget.Box({
            vertical: true,
            children: [
                Widget.Label({
                    xalign: 0,
                    className: 'txt-norm titlefont txt',
                    label: 'Options',
                    hpack: 'center',
                }),
                //////////////////
                ConfigToggle({
                    icon: 'dark_mode',
                    name: 'Dark Mode',
                    desc: 'Ya should go to sleep!',
                    initValue: darkMode.value,
                    onChange: (_, newValue) => {
                        darkMode.value = !!newValue;
                    },
                    extraSetup: (self) => self.hook(darkMode, (self) => {
                        self.enabled.value = darkMode.value;
                    }),
                }),
                ConfigToggle({
                    icon: 'border_clear',
                    name: 'Transparency',
                    desc: 'Make shell elements transparent',
                    initValue: initTransparencyVal,
                    onChange: (self, newValue) => {
                        let transparency = newValue == 0 ? "opaque" : "transparent";
                        execAsync([`bash`, `-c`, `mkdir -p ${GLib.get_user_state_dir()}/ags/user && sed -i "2s/.*/${transparency}/"  ${GLib.get_user_state_dir()}/ags/user/colormode.txt`])
                            .then(execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/switchcolor.sh`]))
                            .catch(print);
                    },
                }),
                Widget.Box({
                    tooltipText: 'Theme GTK apps using accent color\n(drawback: dark/light mode switching requires restart)',
                    className: 'txt spacing-h-5 configtoggle-box',
                    children: [
                        MaterialIcon('imagesearch_roller', 'norm'),
                        Widget.Label({
                            className: 'txt txt-small',
                            label: 'Use Gradience',
                        }),
                        Widget.Box({ hexpand: true }),
                        ConfigMulipleSelection({
                            hpack: 'center',
                            vpack: 'center',
                            optionsArr: [
                                [{ name: 'Off', value: 0 }, { name: 'On', value: 1 }],
                            ],
                            initIndex: [-1, -1],
                            onChange: (value, name) => {
                                const ADWAITA_BLUE = "#3584E4";
                                if (value) execAsync([`bash`, `-c`, `${App.configDir}/scripts/color_generation/switchcolor.sh - --yes-gradience`, `&`])
                                    .catch(print);
                                else execAsync([`bash`, `-c`, `${App.configDir}/scripts/color_generation/switchcolor.sh "${ADWAITA_BLUE}" --no-gradience`, `&`])
                                    .catch(print);

                            },
                        }),
                    ]
                }),
            ]
        }),
        Widget.Box({
            vertical: true,
            className: 'spacing-v-5',
            children: [
                Widget.Label({
                    xalign: 0,
                    className: 'txt-norm titlefont txt margin-top-5',
                    label: 'Scheme styles',
                    hpack: 'center',
                }),
                //////////////////
                ConfigMulipleSelection({
                    hpack: 'center',
                    vpack: 'center',
                    optionsArr: schemeOptionsArr,
                    initIndex: initSchemeIndex,
                    onChange: (value, name) => {
                        execAsync([`bash`, `-c`, `mkdir -p ${GLib.get_user_state_dir()}/ags/user && sed -i "3s/.*/${value}/" ${GLib.get_user_state_dir()}/ags/user/colormode.txt`])
                            .then(execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/switchcolor.sh`]))
                            .catch(print);
                    },
                }),
            ]
        })
    ]
});

const ColorschemeContent = () => Widget.Box({
    className: 'osd-colorscheme spacing-v-5',
    vertical: true,
    hpack: 'center',
    children: [
        Widget.Label({
            xalign: 0,
            className: 'txt-norm titlefont txt',
            label: 'Color scheme',
            hpack: 'center',
        }),
        Widget.Box({
            className: 'spacing-h-5',
            hpack: 'center',
            children: [
                ColorBox({ name: 'P', className: 'osd-color osd-color-primary' }),
                ColorBox({ name: 'S', className: 'osd-color osd-color-secondary' }),
                ColorBox({ name: 'T', className: 'osd-color osd-color-tertiary' }),
                ColorBox({ name: 'Sf', className: 'osd-color osd-color-surface' }),
                ColorBox({ name: 'Sf-i', className: 'osd-color osd-color-inverseSurface' }),
                ColorBox({ name: 'E', className: 'osd-color osd-color-error' }),
            ]
        }),
        Widget.Box({
            className: 'spacing-h-5',
            hpack: 'center',
            children: [
                ColorBox({ name: 'P-c', className: 'osd-color osd-color-primaryContainer' }),
                ColorBox({ name: 'S-c', className: 'osd-color osd-color-secondaryContainer' }),
                ColorBox({ name: 'T-c', className: 'osd-color osd-color-tertiaryContainer' }),
                ColorBox({ name: 'Sf-c', className: 'osd-color osd-color-surfaceContainer' }),
                ColorBox({ name: 'Sf-v', className: 'osd-color osd-color-surfaceVariant' }),
                ColorBox({ name: 'E-c', className: 'osd-color osd-color-errorContainer' }),
            ]
        }),
        ColorSchemeSettingsRevealer(),
    ]
});

const isHoveredColorschemeSettings = Variable(false);

export default () => Widget.Revealer({
    transition: 'slide_down',
    transitionDuration: userOptions.animations.durationLarge,
    child: ColorschemeContent(),
    setup: (self) => {
        self
            .hook(showColorScheme, (revealer) => {
                if (showColorScheme.value == true)
                    revealer.revealChild = true;
                else
                    revealer.revealChild = isHoveredColorschemeSettings.value;
            })
            .hook(isHoveredColorschemeSettings, (revealer) => {
                if (isHoveredColorschemeSettings.value == false) {
                    setTimeout(() => {
                        if (isHoveredColorschemeSettings.value == false)
                            revealer.revealChild = showColorScheme.value;
                    }, 2000);
                }
            })
    },
})
