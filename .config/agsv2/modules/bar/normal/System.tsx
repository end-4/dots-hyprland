import { bind, exec, execAsync, GLib, interval, readFileAsync, Variable, writeFileAsync } from 'astal';
import { userOptions } from '../../core/configuration/user_options';
import { App, Astal, Gdk, Gtk } from 'astal/gtk3';
import { AnimatedCircProg } from '../../core/commonwidgets/CairoCircularProgress';
import AstalBattery from 'gi://AstalBattery';
import { BoxProps, Button, DrawingArea } from 'astal/gtk3/widget';
import { setupCursorHover } from '../../core/widgetutils/cursorhover';
import { getString } from '../../../i18n/i18n';
import { toggleWindowOnAllMonitors } from '../../../variables';
import { MaterialIcon } from '../../core/commonwidgets/MaterialIcon';
import { WEATHER_SYMBOL, WWO_CODE } from '../../core/commondata/weather';

const battery = AstalBattery.get_default();
const WEATHER_CACHE_FOLDER = `${GLib.get_user_cache_dir()}/agsv2/weather`;
const WEATHER_CACHE_PATH = `${WEATHER_CACHE_FOLDER}/wttr.in.txt`;
exec(`mkdir -p ${WEATHER_CACHE_FOLDER}`);

function BarBatteryProgress() {
    let circprog: DrawingArea;
    bind(battery, 'percentage').subscribe((percentage) => _updateProgress(circprog!, percentage));

    function _updateProgress(self: DrawingArea, percentage = battery.percentage) {
        circprog = self;
        circprog.css = `font-size: ${Math.abs(percentage)}px;`;
        circprog.toggleClassName('bar-batt-circprog-low', percentage <= userOptions.battery.low);
        circprog.toggleClassName('bar-batt-circprog-full', percentage === 100);
    }

    return (
        <AnimatedCircProg
            className={`bar-batt-circprog ${userOptions.appearance.borderless ? 'bar-batt-circprog-borderless' : ''}`}
            valign={Gtk.Align.CENTER}
            halign={Gtk.Align.CENTER}
            extraSetup={_updateProgress}
        />
    );
}

function BarClock() {
    const time = Variable(GLib.DateTime.new_now_local().format(userOptions.time.format)!);
    interval(userOptions.time.interval, () => {
        time.set(GLib.DateTime.new_now_local().format(userOptions.time.format)!);
    });

    const date = Variable(GLib.DateTime.new_now_local().format(userOptions.time.dateFormatLong)!);
    interval(userOptions.time.dateInterval, () => {
        date.set(GLib.DateTime.new_now_local().format(userOptions.time.dateFormatLong)!);
    });

    return (
        <BarGroup>
            <box className="spacing-h-4 bar-clock-box">
                <label className="bar-time" label={bind(time)}></label>
                <label className="txt-norm txt-onLayer1" label="•"></label>
                <label className="txt-smallie bar-date" label={bind(date)}></label>
            </box>
        </BarGroup>
    );
}

function UtilButton({ name, icon, onClicked }: { name: string; icon: string; onClicked: (button: Button) => void }) {
    return (
        <button
            valign={Gtk.Align.CENTER}
            tooltipText={name}
            onClicked={onClicked}
            className={`bar-util-btn ${
                userOptions.appearance.borderless ? 'bar-util-btn-borderless' : ''
            } icon-material txt-norm`}
            label={icon}
            setup={setupCursorHover}
        />
    );
}

function Utilities() {
    return (
        <box halign={Gtk.Align.CENTER} className="spacing-h-4">
            <UtilButton
                name={getString('Screen snip')}
                icon="screenshot_region"
                onClicked={() =>
                    execAsync(`${GLib.get_user_config_dir()}/agsv2/scripts/grimblast.sh copy area`).catch(print)
                }
            />
            <UtilButton
                name={getString('Color picker')}
                icon="colorize"
                onClicked={() => execAsync(['hyprpicker', '-a']).catch(print)}
            />
            <UtilButton
                name={getString('Toggle on-screen keyboard')}
                icon="keyboard"
                onClicked={() => toggleWindowOnAllMonitors('osk')}
            />
        </box>
    );
}

function BarBattery() {
    return (
        <box className="spacing-h-4 bar-batt-txt">
            <revealer
                transitionDuration={userOptions.animations.durationSmall}
                revealChild={bind(battery, 'charging')}
                transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}
            >
                <MaterialIcon icon="bolt" size="norm" tooltipText="Charging" />
            </revealer>
            <label
                className="txt-smallie"
                label={bind(battery, 'percentage').as((percentage) => `${Number.parseFloat(percentage.toFixed(1))}%`)}
            />
            <overlay overlays={[<BarBatteryProgress />]}>
                <box
                    valign={Gtk.Align.CENTER}
                    className={bind(battery, 'percentage').as(
                        (percentage) =>
                            `bar-batt ${
                                percentage <= userOptions.battery.low
                                    ? 'bar-batt-low'
                                    : percentage === 100 && 'bar-batt-full'
                            }`
                    )}
                    homogeneous={true}
                >
                    <MaterialIcon icon="battery_full" size="small" />
                </box>
            </overlay>
        </box>
    );
}

function BarGroup({ child, children, ...args }: BoxProps) {
    return (
        <box {...args} className="bar-group-margin bar-sides">
            <box
                className={`bar-group${
                    userOptions.appearance.borderless ? '-borderless' : ''
                } bar-group-standalone bar-group-pad-system`}
            >
                {child || children}
            </box>
        </box>
    );
}

function BatteryModule() {
    const data = Variable({ symbol: 'device_thermostat', temperature: 'Weather', description: '' });

    function update(output: string) {
        const weather = JSON.parse(output);
        const weatherCode = weather.current_condition[0].weatherCode as keyof typeof WWO_CODE;
        const weatherDesc = weather.current_condition[0].weatherDesc[0].value;
        const temperature = weather.current_condition[0][`temp_${userOptions.weather.preferredUnit}`];
        const feelsLike = weather.current_condition[0][`FeelsLike${userOptions.weather.preferredUnit}`];
        const weatherSymbol = WEATHER_SYMBOL[WWO_CODE[weatherCode] as keyof typeof WEATHER_SYMBOL];
        data.set({
            symbol: weatherSymbol,
            temperature: `${temperature}°${userOptions.weather.preferredUnit} • ${getString(
                'Feels like'
            )} ${feelsLike}°${userOptions.weather.preferredUnit}`,
            description: weatherDesc,
        });
    }

    async function updateWeatherForCity(city: string) {
        try {
            const output = await execAsync(`curl https://wttr.in/${city.replace(/ /g, '%20')}?format=j1`);
            update(output);
            await writeFileAsync(WEATHER_CACHE_PATH, output).catch(print);
        } catch {
            // Read from cache
            await readFileAsync(WEATHER_CACHE_PATH).then(update).catch(print);
        }
    }

    interval(15 * 60 * 1000, async () => {
        if (userOptions.weather.city != '' && userOptions.weather.city != null) {
            await updateWeatherForCity(userOptions.weather.city.replace(/ /g, '%20'));
        } else {
            const output = await execAsync('curl ipinfo.io');
            const city = JSON.parse(output)['city'].toLowerCase();
            await updateWeatherForCity(city);
        }
    });

    return (
        <stack
            transitionType={Gtk.StackTransitionType.SLIDE_UP_DOWN}
            transitionDuration={userOptions.animations.durationLarge}
            shown={bind(battery, 'isBattery').as((isBattery) => (isBattery ? 'laptop' : 'desktop'))}
        >
            <box name="laptop" className="spacing-h-4">
                <BarGroup>
                    <Utilities />
                </BarGroup>
                <BarGroup>
                    <BarBattery />
                </BarGroup>
            </box>
            <BarGroup name="desktop">
                {bind(data).as((data) => (
                    <box
                        className="spacing-h-4 txt-onSurfaceVariant"
                        halign={Gtk.Align.CENTER}
                        hexpand={true}
                        tooltipText={data.description}
                    >
                        <MaterialIcon icon={data.symbol} size="small" />
                        <label label={data.temperature} />
                    </box>
                ))}
            </BarGroup>
        </stack>
    );
}

const switchToRelativeWorkspace = async (num: number) => {
    try {
        const hypr = (await import('gi://AstalHyprland')).default.get_default();
        hypr.message_async(`dispatch workspace r${num > 0 ? '+' : ''}${num}`, null);
    } catch (error) {
        print(error)
        execAsync([`${GLib.get_user_config_dir()}/agsv2/scripts/sway/swayToRelativeWs.sh`, `${num}`]).catch(print);
    }
};

export default function System() {
    function onClick(_: Astal.EventBox, event: Astal.ClickEvent) {
        switch (event.button) {
            case Astal.MouseButton.PRIMARY:
                App.toggle_window('sideright');
                break;
        }
    }

    function onScroll(_: Astal.EventBox, event: Astal.ScrollEvent) {
        if (event.direction === Gdk.ScrollDirection.SMOOTH) {
            if (event.delta_y < 0) {
                event.direction = Gdk.ScrollDirection.UP;
            } else {
                event.direction = Gdk.ScrollDirection.DOWN;
            }
        }

        if (event.direction === Gdk.ScrollDirection.UP) {
            switchToRelativeWorkspace(-1);
        } else if (event.direction === Gdk.ScrollDirection.DOWN) {
            switchToRelativeWorkspace(+1);
        }
    }

    return (
        <eventbox onScroll={onScroll} onClick={onClick}>
            <box className="spacing-h-4">
                <BarClock />
                <BatteryModule />
            </box>
        </eventbox>
    );
}
