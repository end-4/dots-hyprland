import { Astal, Gdk, Gtk, App } from 'astal/gtk3';
import { bind } from 'astal';
import AstalTray from 'gi://AstalTray';
import Wp from 'gi://AstalWp';
import { execAsync } from 'astal/process';
import Tray from './Tray';
import StatusIcons from '../../core/commonwidgets/StatusIcons';
import { Box } from 'astal/gtk3/widget';

function SeparatorDot() {
    const tray = AstalTray.get_default();

    return (
        <revealer
            transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
            revealChild={bind(tray, 'items').as((items) => {
                const filtered = items.filter((item) => item.id != null);
                return filtered.length > 0;
            })}
        >
            <box className="separator-circle" valign={Gtk.Align.CENTER} />
        </revealer>
    );
}

export default function Indicators({ gdkmonitor, monitorId }: { gdkmonitor: Gdk.Monitor; monitorId: number }) {
    const audio = Wp.get_default()?.audio;
    let statusIcons: Box;

    bind(App, 'activeWindow').subscribe((active) => {
        if (!active) statusIcons.toggleClassName('bar-statusicons-active', false);
        statusIcons.toggleClassName('bar-statusicons-active', active.name === 'sideright');
    });

    function onScroll(_: Astal.EventBox, event: Astal.ScrollEvent) {
        if (!audio) return;
        const speaker = audio.defaultSpeaker;

        if (event.direction === Gdk.ScrollDirection.SMOOTH) {
            if (event.delta_y < 0) {
                event.direction = Gdk.ScrollDirection.UP;
            } else {
                event.direction = Gdk.ScrollDirection.DOWN;
            }
        }

        const step = speaker.volume <= 0.09 ? 0.01 : 0.03;

        if (event.direction === Gdk.ScrollDirection.UP) {
            speaker.volume += step;
        } else if (event.direction === Gdk.ScrollDirection.DOWN) {
            speaker.volume -= step;
        }
    }

    function onClick(_: Astal.EventBox, event: Astal.ClickEvent) {
        // HACK: to prevent the error:
        //
        // astal-Message: 16:37:51.097: Error: 8 is not a valid value for enumeration MouseButton
        // onClick@file:///run/user/1000/ags.js:1461:19
        // _init/GLib.MainLoop.prototype.runAsync/</<@resource:///org/gnome/gjs/modules/core/overrides/GLib.js:263:34
        try {
            Number(event.button);
        } catch (error) {
            const button = Number((error as string).toString().at(7));
            switch (button) {
                case 8:
                    event.button = Astal.MouseButton.BACK;
                    break;
                case 9:
                    event.button = Astal.MouseButton.FORWARD;
                    break;
                default:
                    break;
            }
        }

        switch (event.button) {
            case Astal.MouseButton.PRIMARY:
                App.toggle_window('sideright');
                break;
            case Astal.MouseButton.SECONDARY:
                execAsync([
                    'bash',
                    '-c',
                    'playerctl next',
                    '||',
                    'playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"` &',
                ]).catch(print);
                break;
            case Astal.MouseButton.MIDDLE:
                execAsync('playerctl play-pause').catch(print);
                break;
            case Astal.MouseButton.BACK:
                execAsync('playerctl previous').catch(print);
        }
    }

    return (
        <eventbox
            onScroll={onScroll}
            onClick={onClick}
            onHover={() => statusIcons.toggleClassName('bar-statusicons-hover', true)}
            onHoverLost={() => statusIcons.toggleClassName('bar-statusicons-hover', false)}
        >
            <box className="spacing-h-5 bar-spaceright" hexpand={true}>
                <box hexpand={true} />
                <Tray />
                <box>
                    <SeparatorDot />
                    <StatusIcons className="bar-statusicons" setup={(self) => (statusIcons = self)} />
                </box>
            </box>
        </eventbox>
    );
}
