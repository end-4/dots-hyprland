import { Gtk } from "astal/gtk3"
import { bind, Variable } from "astal"
import Hyprland from "gi://AstalHyprland"
import { userOptions } from "../../core/configuration/user_options";

interface Workspace {
    id: number;
    occupied: boolean;
    active: boolean;
    roundLeft: boolean;
    roundRight: boolean;
}

export default function Workspaces({ count = userOptions.workspaces.shown }: { count?: number }) {
    const hypr = Hyprland.get_default()
    const activeWs = bind(hypr, "focusedWorkspace").as(ws => ws!.id)
    const workspaces = bind(hypr, "workspaces")
    const padded = Variable.derive(
        [activeWs, workspaces],
        (activeWs, workspaces) => {
            const padded: Workspace[] = [];
            const occupied = new Map<number, Workspace>();
            for (const workspace of workspaces) {
                occupied.set(workspace.id, {
                    id: workspace.id,
                    occupied: workspace.clients.length > 0,
                    active: workspace.id === activeWs,
                    roundLeft: true,
                    roundRight: true,
                });
            }

            const offset = Math.floor((activeWs - 1) / count) * count;

            for (let index = 0 + offset; index < count + offset; index++) {
                let element = occupied.get(index + 1);
                if (element == undefined) {
                    element = {
                        id: index + 1,
                        occupied: false,
                        active: false,
                        roundLeft: true,
                        roundRight: true,
                    };
                }
                padded.push(element);

                if (index == offset) continue;

                if (element.occupied && padded[index - offset - 1].occupied) {
                    element.roundLeft = false;
                    padded[index - offset - 1].roundRight = false;
                }
            }
            return padded;
        }
    )

    return <box className="bar-group-margin" onDestroy={padded.drop}>
        <box className="bar-group bar-group-standalone bar-group-pad">
            <box className="bar-ws-container bar-ws-width" homogeneous={true}>
                {bind(padded).as(ws => ws.map((workspace, i) => {
                    return <box
                        valign={Gtk.Align.CENTER}
                        halign={Gtk.Align.CENTER}
                        css={`border-radius: ${workspace.roundLeft ? "10rem" : "0"} ${workspace.roundRight ? "10rem" : "0"} ${workspace.roundRight ? "10rem" : "0"} ${workspace.roundLeft ? "10rem" : "0"}`}
                        className={`bar-ws bar-ws-${workspace.occupied ? "occupied" : "empty"}`} >
                        <box className={workspace.active ? "bar-ws-active" : ""}>
                            <label hexpand={true} halign={Gtk.Align.CENTER} >
                                {workspace.id}
                            </label>
                        </box>
                    </box>
                }))}
            </box>
        </box>
    </box>
} 