import { Gdk, Gtk } from "astal/gtk3"
import { bind, Variable } from "astal"
import Hyprland from "gi://AstalHyprland"

export default function WindowTitle({ gdkmonitor, monitorId }: { gdkmonitor: Gdk.Monitor, monitorId: number }) {
    const hypr = Hyprland.get_default();
    const focusedClient = bind(hypr, "focusedClient");
    const focusedWorkspace = bind(hypr, "focusedWorkspace");
    const focused = Variable.derive(
        [focusedClient, focusedWorkspace],
        (client, workspace) => {
            return { client, workspace };
        }
    );
    const scrollPos = () => Gtk.Adjustment.new(6, 0, 100, 1, 10, 0);

    return <box className="bar-space-button" vertical={true} onDestroy={focused.drop}>
        <scrollable
            hexpand={true}
            vexpand={true}
            hscroll={Gtk.PolicyType.AUTOMATIC}
            vscroll={Gtk.PolicyType.NEVER}
        >
            {bind(focused).as(f => {
                const topdesc = f.client == null ? "Desktop" : bind(f.client, "class").as((_class) => _class ?? "Desktop");
                const title = f.client == null ? `Workspace ${f.workspace?.id ?? ""}` : bind(f.client, "title").as((title) => title ?? `Workspace ${f.workspace?.id ?? ""}`);
                const vadjustment = f.client == null ? scrollPos() : bind(f.client, "title").as(_ => scrollPos());

                return <box vertical={true}>
                    <label
                        xalign={0}
                        halign={Gtk.Align.START}
                        truncate={true}
                        className="txt-smaller bar-wintitle-topdesc txt"
                        label={topdesc}
                    />
                    <scrollable
                        // HACK: To prevent Japanese characters from being cut off
                        hexpand={true}
                        vexpand={true}
                        hscroll={Gtk.PolicyType.EXTERNAL}
                        vscroll={Gtk.PolicyType.EXTERNAL}
                        vadjustment={vadjustment}
                    >
                        <label
                            xalign={0}
                            halign={Gtk.Align.START}
                            truncate={true}
                            className="txt-smallie bar-wintitle-txt"
                            label={title}
                        />
                    </scrollable>
                </box>
            })}
        </scrollable>
    </box >
} 