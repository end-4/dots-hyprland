import { bind, exec, execAsync, GLib, interval, readFile, Variable } from "astal";
import AstalMpris from "gi://AstalMpris";

import { AnimatedCircProg } from "../../core/commonwidgets/CairoCircularProgress";
import { MaterialIcon } from "../../core/commonwidgets/MaterialIcon";
import { showMusicControls } from '../../../variables';
import { Astal, Gdk, Gtk } from "astal/gtk3";
import { userOptions } from "../../core/configuration/user_options";
import { getString } from "../../../i18n/i18n";
import { DrawingArea, Revealer } from "astal/gtk3/widget";

const CUSTOM_MODULE_CONTENT_INTERVAL_FILE = `${GLib.get_user_cache_dir()}/agsv2/user/scripts/custom-module-interval.txt`;
const CUSTOM_MODULE_CONTENT_SCRIPT = `${GLib.get_user_cache_dir()}/agsv2/user/scripts/custom-module-poll.sh`;
const CUSTOM_MODULE_LEFTCLICK_SCRIPT = `${GLib.get_user_cache_dir()}/agsv2/user/scripts/custom-module-leftclick.sh`;
const CUSTOM_MODULE_RIGHTCLICK_SCRIPT = `${GLib.get_user_cache_dir()}/agsv2/user/scripts/custom-module-rightclick.sh`;
const CUSTOM_MODULE_MIDDLECLICK_SCRIPT = `${GLib.get_user_cache_dir()}/agsv2/user/scripts/custom-module-middleclick.sh`;
const CUSTOM_MODULE_SCROLLUP_SCRIPT = `${GLib.get_user_cache_dir()}/agsv2/user/scripts/custom-module-scrollup.sh`;
const CUSTOM_MODULE_SCROLLDOWN_SCRIPT = `${GLib.get_user_cache_dir()}/agsv2/user/scripts/custom-module-scrolldown.sh`;

const mpris = AstalMpris.get_default();

function trimTrackTitle(title: string) {
    if (!title) return '';
    const cleanPatterns = [
        /【[^】]*】/,        // Touhou n weeb stuff
        " [FREE DOWNLOAD]", // F-777
    ];
    cleanPatterns.forEach((expr) => title = title.replace(expr, ''));
    return title;
}

function plasma(players: AstalMpris.Player[]) {
    return players.find((player) => player.busName === "org.mpris.MediaPlayer2.plasma-browser-integration");
}

function BarResource({
    name,
    icon,
    command,
    circprogClassName = `bar-batt-circprog ${userOptions.appearance.borderless ? 'bar-batt-circprog-borderless' : ''}`,
    textClassName = 'txt-onSurfaceVariant',
    iconClassName = 'bar-batt'
}: {
    name: string;
    icon: string;
    command: string;
    circprogClassName?: string;
    textClassName?: string;
    iconClassName?: string;
}
) {
    function onClick(_: Astal.Button, event: Astal.ClickEvent) {
        switch (event.button) {
            case Astal.MouseButton.PRIMARY:
                execAsync(['bash', '-c', `${userOptions.apps.taskManager}`]).catch(print);
                break
        }
    }

    const percentage = Variable(0);

    interval(5000, () => {
        execAsync(['bash', '-c', command]).then((output: string) => {
            percentage.set(Number(output));
        }).catch(print);
    });

    return <button onClick={onClick} tooltipText={bind(percentage).as(percentage => `${name}: ${Math.round(percentage)}%`)} >
        <box className={`spacing-h-4 ${textClassName}`}>
            <box homogeneous={true}>
                <overlay>
                    <box valign={Gtk.Align.CENTER} className={iconClassName} homogeneous={true}>
                        <MaterialIcon icon={icon} size="small" />
                    </box>
                    <overlay>
                        <AnimatedCircProg
                            className={circprogClassName}
                            valign={Gtk.Align.CENTER}
                            halign={Gtk.Align.CENTER}
                            css={bind(percentage).as(percentage => `font-size: ${percentage}px;`)}
                        />
                    </overlay>
                </overlay>
            </box>
            <label className={`txt-smallie ${textClassName}`}>
                {bind(percentage).as(percentage => `${Math.round(percentage)}%`)}
            </label>
        </box>
    </button>

}

function TrackProgress() {
    let drawingarea: DrawingArea;
    bind(mpris, "players").subscribe(players => extraSetup(drawingarea!, players))

    function extraSetup(self: DrawingArea, players: AstalMpris.Player[] = mpris.players) {
        drawingarea = self;
        const player = plasma(players);
        if (!player) return drawingarea!.css = `font-size: ${userOptions.appearance.borderless ? 100 : 0}px`;
        drawingarea!.css = `font-size: ${Math.max(player.position / player.length * 100, 0)}px;`;
        bind(player, "position").subscribe(position => {
            drawingarea!.css = `font-size: ${Math.max(position / player.length * 100, 0)}px;`;
        })
    }

    return <AnimatedCircProg
        className={`bar-music-circprog ${userOptions.appearance.borderless ? 'bar-music-circprog-borderless' : ''}`}
        valign={Gtk.Align.CENTER}
        halign={Gtk.Align.CENTER}
        extraSetup={extraSetup}
    />
}

function CustomModule() {
    const content = Variable("");

    interval(Number(readFile(CUSTOM_MODULE_CONTENT_INTERVAL_FILE)) || 5000, () => {
        content.set(exec(CUSTOM_MODULE_CONTENT_SCRIPT));
    })

    function onClick(_: Astal.Button, event: Astal.ClickEvent) {
        switch (event.button) {
            case Astal.MouseButton.PRIMARY:
                execAsync(CUSTOM_MODULE_LEFTCLICK_SCRIPT).catch(print)
                break
            case Astal.MouseButton.SECONDARY:
                execAsync(CUSTOM_MODULE_RIGHTCLICK_SCRIPT).catch(print)
                break
            case Astal.MouseButton.MIDDLE:
                execAsync(CUSTOM_MODULE_MIDDLECLICK_SCRIPT).catch(print)
                break
        }
    }

    function onScroll(_: Astal.Button, event: Astal.ScrollEvent) {
        if (event.direction === Gdk.ScrollDirection.SMOOTH) {
            if (event.delta_y < 0) {
                event.direction = Gdk.ScrollDirection.UP;
            } else {
                event.direction = Gdk.ScrollDirection.DOWN;
            }
        }

        if (event.direction === Gdk.ScrollDirection.UP) {
            execAsync(CUSTOM_MODULE_SCROLLUP_SCRIPT).catch(print)
        } else if (event.direction === Gdk.ScrollDirection.DOWN) {
            execAsync(CUSTOM_MODULE_SCROLLDOWN_SCRIPT).catch(print)
        }
    }

    return <box className={`bar-group-margin bar-sides`}>
        <box className={`bar-group${userOptions.appearance.borderless ? '-borderless' : ''} bar-group-standalone bar-group-pad-system`}>
            <button onClick={onClick} onScroll={onScroll} >
                <label className={`txt-smallie txt-onSurfaceVariant`} useMarkup={true}>
                    {bind(content)}
                </label>
            </button>
        </box>
    </box>
}

function SystemResources() {
    let revealer: Revealer | undefined;
    bind(mpris, "players").subscribe(players => setup(revealer!, players))

    function setup(self: Revealer, players: AstalMpris.Player[] = mpris.players) {
        revealer = self;
        const player = plasma(players);
        if (!player) return revealer!.revealChild = true;
        revealer!.revealChild = false;
    }

    return <box className={`bar-group-margin bar-sides`}>
        <box className={`bar-group${userOptions.appearance.borderless ? '-borderless' : ''} bar-group-standalone bar-group-pad-system`}>
            <box>
                <BarResource
                    name={getString("RAM Usage")}
                    icon="memory"
                    command={`LANG=C free | awk '/^Mem/ {printf("%.2f\\n", ($3/$2) * 100)}'`}
                    circprogClassName={`bar-ram-circprog ${userOptions.appearance.borderless ? 'bar-ram-circprog-borderless' : ''}`}
                    textClassName="bar-ram-txt"
                    iconClassName="bar-ram-icon"
                />
            </box>
            <revealer
                setup={setup}
                transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
                transitionDuration={userOptions.animations.durationLarge}
            >
                <box className="spacing-h-10 margin-left-10">
                    <BarResource
                        name={getString("Swap Usage")}
                        icon="swap_horiz"
                        command={`LANG=C free | awk '/^Swap/ {if ($2 > 0) printf("%.2f\\n", ($3/$2) * 100); else print "0";}'`}
                        circprogClassName={`bar-swap-circprog ${userOptions.appearance.borderless ? 'bar-swap-circprog-borderless' : ''}`}
                        textClassName="bar-swap-txt"
                        iconClassName="bar-swap-icon"
                    />
                    <BarResource
                        name={getString("CPU Usage")}
                        icon="settings_motion_mode"
                        command={`LANG=C top -bn1 | grep Cpu | sed 's/\\,/\\./g' | awk '{print $2}'`}
                        circprogClassName={`bar-cpu-circprog ${userOptions.appearance.borderless ? 'bar-cpu-circprog-borderless' : ''}`}
                        textClassName="bar-cpu-txt"
                        iconClassName="bar-cpu-icon"
                    />
                </box>
            </revealer>
        </box>
    </box>
}


export default function Music() {
    let playback: Astal.Label | undefined;
    bind(mpris, "players").subscribe(players => playbackSetup(playback!, players))

    function playbackSetup(self: Astal.Label, players: AstalMpris.Player[] = mpris.players) {
        playback = self;
        const player = plasma(players);
        if (!player) return playback.label = "play_arrow"
        if (player.playbackStatus === AstalMpris.PlaybackStatus.PLAYING) {
            playback!.label = "pause";
        } else {
            playback!.label = "play_arrow";
        }
        bind(player, "playbackStatus").subscribe(status => {
            if (status === AstalMpris.PlaybackStatus.PLAYING) {
                playback!.label = "pause";
            } else {
                playback!.label = "play_arrow";
            }
        })
    }

    let name: Astal.Label | undefined;
    bind(mpris, "players").subscribe(players => nameSetup(name!, players))

    function nameSetup(self: Astal.Label, players: AstalMpris.Player[] = mpris.players) {
        name = self;
        const player = plasma(players);
        if (!player) return name.label = getString("No media")
        name!.label = `${trimTrackTitle(player.title)} • ${player.artist ?? getString("Unknown artist")}`;
        const display = Variable.derive(
            [bind(player, "title"), bind(player, "artist")],
            (title, artist) => {
                return `${trimTrackTitle(title)} • ${artist ?? getString("Unknown artist")}`;
            }
        )
        display.subscribe(display => {
            name!.label = display;
        })
    }

    function onScroll(_: Astal.EventBox, event: Astal.ScrollEvent) {
        if (!mpris.players[0]) return;

        if (event.direction === Gdk.ScrollDirection.SMOOTH) {
            if (event.delta_y < 0) {
                event.direction = Gdk.ScrollDirection.UP;
            } else {
                event.direction = Gdk.ScrollDirection.DOWN;
            }
        }

        const step = 0.1; // We use a larger step because this is player instance volume, not global
        if (event.direction === Gdk.ScrollDirection.UP) {
            mpris.players[0].volume += step;
        } else if (event.direction === Gdk.ScrollDirection.DOWN) {
            mpris.players[0].volume -= step;
        }
    }

    function onClick(_: Astal.EventBox, event: Astal.ClickEvent) {
        switch (event.button) {
            case Astal.MouseButton.PRIMARY:
                showMusicControls.set(!showMusicControls.get())
                break
            case Astal.MouseButton.SECONDARY:
                execAsync(['bash', '-c', 'playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"` &']).catch(print)
                break
            case Astal.MouseButton.MIDDLE:
                execAsync('playerctl play-pause').catch(print)
                break
        }
    }

    return <eventbox onScroll={onScroll}>
        <box className={`spacing-h-4`} >
            {GLib.file_test(CUSTOM_MODULE_CONTENT_SCRIPT, GLib.FileTest.EXISTS) ?
                <CustomModule /> :
                <SystemResources />
            }
            <eventbox onClick={onClick}>
                <box className={`bar-group-margin bar-sides`}>
                    <box className={`bar-group${userOptions.appearance.borderless ? '-borderless' : ''} bar-group-standalone bar-group-pad-system`}>
                        <box className={`spacing-h-10`} hexpand={true}>
                            <box homogeneous={true}>
                                <overlay overlays={[TrackProgress()]}>
                                    <box valign={Gtk.Align.CENTER} className="bar-music-playstate" homogeneous={true} >
                                        <label
                                            valign={Gtk.Align.CENTER}
                                            className={"bar-music-playstate-txt"}
                                            justify={Gtk.Justification.CENTER}
                                            setup={playbackSetup}
                                        />
                                    </box>
                                </overlay>
                            </box>
                            <label
                                hexpand={true}
                                className={'txt-smallie bar-music-txt'}
                                truncate={true} maxWidthChars={1}
                                setup={nameSetup}
                            />
                        </box>
                    </box>
                </box>
            </eventbox>
        </box>
    </eventbox>
}