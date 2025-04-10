import { App, Astal, Gdk, Gtk } from 'astal/gtk3';
import { bind } from 'astal';
import { currentShellMode } from '../../variables.js';
import { userOptions } from '../core/configuration/user_options';

import WindowTitle from './normal/SpaceLeft.js';
import Indicators from './normal/SpaceRight.js';
import Music from './normal/Music';
import System from './normal/System';
import NormalWorkspaces from './normal/WorkspacesHyprland';

export function Bar({ gdkmonitor, monitorId }: { gdkmonitor: Gdk.Monitor; monitorId: number }) {
    const { TOP, LEFT, RIGHT } = Astal.WindowAnchor;

    return (
        <window
            name={`bar${monitorId}`}
            gdkmonitor={gdkmonitor}
            exclusivity={Astal.Exclusivity.EXCLUSIVE}
            anchor={TOP | LEFT | RIGHT}
            application={App}
        >
            <stack
                homogeneous={false}
                transitionType={Gtk.StackTransitionType.SLIDE_UP_DOWN}
                transitionDuration={userOptions.animations.durationLarge}
                visibleChildName={bind(currentShellMode).as((monitors) => monitors[0])}
            >
                {/* Normal Mode */}
                <centerbox className="bar-bg" name="normal">
                    <box homogeneous={false}>
                        <box className="bar-corner-spacing" />
                        <box className="bar-sidemodule" hexpand={true}>
                            <WindowTitle gdkmonitor={gdkmonitor} monitorId={monitorId} />
                        </box>
                    </box>
                    <box className="spacing-h-4">
                        <box className="bar-sidemodule">
                            <Music />
                        </box>
                        <box className="workspaces" homogeneous={true}>
                            <NormalWorkspaces />
                        </box>
                        <box className="bar-sidemodule">
                            <System />
                        </box>
                    </box>
                    <box homogeneous={false}>
                        <box className="bar-sidemodule" hexpand={true}>
                            <Indicators gdkmonitor={gdkmonitor} monitorId={monitorId} />
                        </box>
                        <box className="bar-corner-spacing" />
                    </box>
                </centerbox>

                {/* Focus Mode */}
                <centerbox className="bar-bg-focus" name="focus">
                    <box className="bar-sidemodule" />
                    <box className="spacing-h-4">
                        <box className="bar-sidemodule" />
                        <box className="workspaces" homogeneous={true}>
                            {/* <FocusWorkspaces /> */}
                        </box>
                        <box className="bar-sidemodule" />
                    </box>
                    <box />
                </centerbox>

                {/* Nothing Mode */}
                <centerbox className="bar-bg-nothing" name="nothing"></centerbox>
            </stack>
        </window>
    );
}
