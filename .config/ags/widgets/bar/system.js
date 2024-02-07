// This is for the right pills of the bar. 
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Label, Button, Overlay, Revealer, Scrollable, Stack, EventBox } = Widget;
const { exec, execAsync } = Utils;
const { GLib } = imports.gi;
import Battery from 'resource:///com/github/Aylur/ags/service/battery.js';
import { MaterialIcon } from '../../lib/materialicon.js';
import { AnimatedCircProg } from "../../lib/animatedcircularprogress.js";
import { WWO_CODE, WEATHER_SYMBOL, NIGHT_WEATHER_SYMBOL } from '../../data/weather.js';

const BATTERY_LOW = 20;
const WEATHER_CACHE_FOLDER = `${GLib.get_user_cache_dir()}/ags/weather`;
Utils.exec(`mkdir -p ${WEATHER_CACHE_FOLDER}`);

let WEATHER_CITY = '';
try {
    WEATHER_CITY = GLib.getenv('AGS_WEATHER_CITY');
} catch (e) {
    print(e);
}

const BatBatteryProgress = () => {
    const _updateProgress = (circprog) => { // Set circular progress value
        circprog.css = `font-size: ${Math.abs(Battery.percent)}px;`

        circprog.toggleClassName('bar-batt-circprog-low', Battery.percent <= BATTERY_LOW);
        circprog.toggleClassName('bar-batt-circprog-full', Battery.charged);
    }
    return AnimatedCircProg({
        className: 'bar-batt-circprog',
        vpack: 'center', hpack: 'center',
        extraSetup: (self) => self
            .hook(Battery, _updateProgress)
        ,
    })
}

const BarClock = () => Widget.Box({
    vpack: 'center',
    className: 'spacing-h-5 txt-onSurfaceVariant bar-clock-box',
    children: [
        Widget.Label({
            className: 'bar-clock',
            label: GLib.DateTime.new_now_local().format("%H:%M"),
            setup: (self) => self.poll(5000, label => {
                label.label = GLib.DateTime.new_now_local().format("%H:%M");
            }),
        }),
        Widget.Label({
            className: 'txt-norm',
            label: '•',
        }),
        Widget.Label({
            className: 'txt-smallie',
            label: GLib.DateTime.new_now_local().format("%A, %d/%m"),
            setup: (self) => self.poll(5000, label => {
                label.label = GLib.DateTime.new_now_local().format("%A, %d/%m");
            }),
        }),
    ],
});

const UtilButton = ({ name, icon, onClicked }) => Button({
    vpack: 'center',
    tooltipText: name,
    onClicked: onClicked,
    className: 'bar-util-btn icon-material txt-norm',
    label: `${icon}`,
})

const Utilities = () => Box({
    hpack: 'center',
    className: 'spacing-h-5 txt-onSurfaceVariant',
    children: [
        UtilButton({
            name: 'Screen snip', icon: 'screenshot_region', onClicked: () => {
                Utils.execAsync(['bash', '-c', `grim -g "$(slurp -d -c e2e2e2BB -b 31313122 -s 00000000)" - | wl-copy &`])
                    .catch(print)
            }
        }),
        UtilButton({
            name: 'Color picker', icon: 'colorize', onClicked: () => {
                Utils.execAsync(['hyprpicker', '-a']).catch(print)
            }
        }),
        UtilButton({
            name: 'Toggle on-screen keyboard', icon: 'keyboard', onClicked: () => {
                App.toggleWindow('osk');
            }
        }),
    ]
})

const BarBattery = () => Box({
    className: 'spacing-h-4 txt-onSurfaceVariant',
    children: [
        Revealer({
            transitionDuration: 150,
            revealChild: false,
            transition: 'slide_right',
            child: MaterialIcon('bolt', 'norm', { tooltipText: "Charging" }),
            setup: (self) => self.hook(Battery, revealer => {
                self.revealChild = Battery.charging;
            }),
        }),
        Label({
            className: 'txt-smallie txt-onSurfaceVariant',
            setup: (self) => self.hook(Battery, label => {
                label.label = `${Battery.percent}%`;
            }),
        }),
        Overlay({
            child: Widget.Box({
                vpack: 'center',
                className: 'bar-batt',
                homogeneous: true,
                children: [
                    MaterialIcon('settings_heart', 'small'),
                ],
                setup: (self) => self.hook(Battery, box => {
                    box.toggleClassName('bar-batt-low', Battery.percent <= BATTERY_LOW);
                    box.toggleClassName('bar-batt-full', Battery.charged);
                }),
            }),
            overlays: [
                BatBatteryProgress(),
            ]
        }),
    ]
});

const BarGroup = ({ child }) => Widget.Box({
    className: 'bar-group-margin bar-sides',
    children: [
        Widget.Box({
            className: 'bar-group bar-group-standalone bar-group-pad-system',
            children: [child],
        }),
    ]
});
const BatteryModule = () => Stack({
    transition: 'slide_up_down',
    transitionDuration: 150,
    children: {
        'laptop': Box({
            className: 'spacing-h-5', children: [
                BarGroup({ child: Utilities() }),
                BarGroup({ child: BarBattery() }),
            ]
        }),
        'desktop': BarGroup({
            child: Box({
                hexpand: true,
                hpack: 'center',
                className: 'spacing-h-5',
                children: [
                    MaterialIcon('device_thermostat', 'small'),
                    Label({
                        label: 'Weather',
                    })
                ],
                setup: (self) => self.poll(900000, async (self) => {
                    const WEATHER_CACHE_PATH = WEATHER_CACHE_FOLDER + '/wttr.in.txt';
                    const updateWeatherForCity = (city) => execAsync(`curl https://wttr.in/${city}?format=j1`)
                        .then(output => {
                            const weather = JSON.parse(output);
                            Utils.writeFile(JSON.stringify(weather), WEATHER_CACHE_PATH)
                                .catch(print);
                            const weatherCode = weather.current_condition[0].weatherCode;
                            const weatherDesc = weather.current_condition[0].weatherDesc[0].value;
                            const temperature = weather.current_condition[0].temp_C;
                            const feelsLike = weather.current_condition[0].FeelsLikeC;
                            const weatherSymbol = WEATHER_SYMBOL[WWO_CODE[weatherCode]];
                            self.children[0].label = weatherSymbol;
                            self.children[1].label = `${temperature}℃ • Feels like ${feelsLike}℃`;
                            self.tooltipText = weatherDesc;
                        }).catch((err) => {
                            try { // Read from cache
                                const weather = JSON.parse(
                                    Utils.readFile(WEATHER_CACHE_PATH)
                                );
                                const weatherCode = weather.current_condition[0].weatherCode;
                                const weatherDesc = weather.current_condition[0].weatherDesc[0].value;
                                const temperature = weather.current_condition[0].temp_C;
                                const feelsLike = weather.current_condition[0].FeelsLikeC;
                                const weatherSymbol = WEATHER_SYMBOL[WWO_CODE[weatherCode]];
                                self.children[0].label = weatherSymbol;
                                self.children[1].label = `${temperature}℃ • Feels like ${feelsLike}℃`;
                                self.tooltipText = weatherDesc;
                            } catch (err) {
                                print(err);
                            }
                        });
                    if (WEATHER_CITY != '' && WEATHER_CITY != null) {
                        updateWeatherForCity(WEATHER_CITY);
                    }
                    else {
                        Utils.execAsync('curl ipinfo.io')
                            .then(output => {
                                return JSON.parse(output)['city'].toLowerCase();
                            })
                            .then(updateWeatherForCity);
                    }
                }),
            })
        }),
    },
    setup: (stack) => Utils.timeout(10, () => {
        if (!Battery.available) stack.shown = 'desktop';
        else stack.shown = 'laptop';
    })
})

const switchToRelativeWorkspace = async (self, num) => {
    try {
        const Hyprland = (await import('resource:///com/github/Aylur/ags/service/hyprland.js')).default;
        Hyprland.sendMessage(`dispatch workspace ${num > 0 ? '+' : ''}${num}`);
    } catch {
        execAsync([`${App.configDir}/scripts/sway/swayToRelativeWs.sh`, `${num}`]).catch(print);
    }
}

export default () => Widget.EventBox({
    onScrollUp: (self) => switchToRelativeWorkspace(self, -1),
    onScrollDown: (self) => switchToRelativeWorkspace(self, +1),
    onPrimaryClick: () => App.toggleWindow('sideright'),
    child: Widget.Box({
        className: 'spacing-h-5',
        children: [
            BarGroup({ child: BarClock() }),
            BatteryModule(),
        ]
    })
});
