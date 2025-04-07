import { Astal, Gdk, Gtk, App } from "astal/gtk3"
import { bind } from "astal"
import SystemTray from "gi://AstalTray"
import Wp from "gi://AstalWp"
import { execAsync } from "astal/process"

function SeparatorDot() {
    const tray = SystemTray.get_default()
    const count = bind(tray, "items").as(items => items.length)

    return <revealer
        transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
        revealChild={count.as(count => count > 0)}
    >
        <box className="separator-circle" valign={Gtk.Align.CENTER} />
    </revealer>
}

export default function Indicators({ gdkmonitor, monitorId }: { gdkmonitor: Gdk.Monitor, monitorId: number }) {
    const tray = SystemTray.get_default()
    const audio = Wp.get_default()?.audio

    const handleScroll = (event: Astal.ScrollEvent) => {
        if (!audio) return
        const speaker = audio.defaultSpeaker

        if (event.direction === Gdk.ScrollDirection.SMOOTH) {
            const step = event.delta_y < 0 ? 0.01 : -0.01
            speaker.volume += step
        }

        const step = speaker.volume <= 0.09 ? 0.01 : 0.03
        speaker.volume += event.delta_y < 0 ? step : -step
    }

    const handleClick = (event: Astal.ClickEvent) => {
        switch (event.button) {
            case Astal.MouseButton.PRIMARY:
                App.toggle_window('sideright')
                break
            case Astal.MouseButton.SECONDARY:
                execAsync(['bash', '-c', 'playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"` &']).catch(print)
                break
            case Astal.MouseButton.MIDDLE:
                execAsync('playerctl play-pause').catch(print)
                break
        }
    }

    return <eventbox
        onScroll={(_, event) => handleScroll(event)}
        onClick={(_, event) => handleClick(event)}
    >
        <box className="spacing-h-5 bar-spaceright">
            <box hexpand={true} />
            <box className="bar-tray">
                {bind(tray, "items").as(items =>
                    items.map(item => (
                        <button
                            name={item.title}
                            className="tray-item"
                            onClicked={() => item.activate(0, 0)}
                        >
                            {/* <image icon={item.gicon} /> */}
                        </button>
                    ))
                )}
            </box>
            <box>
                <SeparatorDot />
                <box className="bar-statusicons">
                    {/* Status icons will be implemented later */}
                </box>
            </box>
        </box>
    </eventbox>
} 