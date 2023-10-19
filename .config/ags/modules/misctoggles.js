import { App, Utils, Widget } from '../imports.js';
const { execAsync, exec } = Utils;
import { MaterialIcon } from "./lib/materialicon.js";
import { setupCursorHover } from "./lib/cursorhover.js";

const RECORD_SCRIPT_DIR = `${App.configDir}/scripts/record-script.sh`;
const RECORDER_PROCESS = 'record-script.sh';
const CLOSE_ANIM_TIME = 150;

async function toggleSystemdService(serviceName, button) {
    const serviceState = exec(`systemctl is-enabled ${serviceName}`) == 'enabled';
    // console.log(`pkexec bash -c "systemctl ${serviceState ? 'disable' : 'enable'} ${serviceName}"`)
    exec(`pkexec bash -c "systemctl ${serviceState ? 'disable' : 'enable'} ${serviceName}"`);
    const newServiceState = exec(`systemctl is-enabled ${serviceName}`) == 'enabled';
    button.toggleClassName('sidebar-button-active', newServiceState);
    serviceState.toggleClassName('invisible', newServiceState);
}

const ModuleRecord = (props = {}) => Widget.Button({
    ...props,
    className: 'button-minsize sidebar-button-nopad sidebar-button-alone-normal txt-small',
    onClicked: () => {
        execAsync(['bash', '-c', RECORD_SCRIPT_DIR]).catch(print);
        setTimeout(() => {
            button.toggleClassName('sidebar-button-active', exec(`pidof ${RECORDER_PROCESS} >/dev/null && echo 1 || echo`) == '1');
        }, CLOSE_ANIM_TIME);
    },
    child: MaterialIcon('screen_record', 'larger'),
    setup: button => {
        button.toggleClassName('sidebar-button-active', exec(`pidof ${RECORDER_PROCESS} >/dev/null && echo 1 || echo`));
        setupCursorHover(button);
    }
})

const SystemdService = (serviceName) => {
    const serviceState = Widget.Label({
        className: `icon-material txt-larger`,
        label: 'check',
        setup: label => {
            // label.toggleClassName('invisible', exec(`bash -c "systemctl is-enabled ${serviceName} >/dev/null && echo ON || echo OFF"`) == 'OFF');
        }
    });
    return Widget.Button({
        className: 'button-minsize sidebar-button sidebar-button-alone-normal txt-small',
        onClicked: (button) => {
            toggleSystemdService(serviceName, button);
        },
        setup: button => {
            button.toggleClassName('sidebar-button-active', exec(`systemctl is-enabled ${serviceName}`) == 'enabled');
            setupCursorHover(button);
        },
        child: Widget.Box({
            setup: box => {
                box.pack_start(Widget.Label({
                    xalign: 0,
                    label: serviceName,
                }), true, true, 0);
                // box.pack_end(serviceState, false, false, 0);
            }
        })
    });
}

export const ModuleMiscToggles = () => {
    const PowerSavers = Widget.Revealer({
        revealChild: false,
        transition: 'slide_left',
        transitionDuration: 100,
        child: Widget.Box({
            className: 'spacing-v-5 margin-right-10',
            vertical: true,
            children: [
                SystemdService('tlp'),
                SystemdService('auto-cpufreq'),
            ]
        })
    })
    const ModulePowerSavers = Widget.Button({
        className: 'button-minsize sidebar-button-nopad sidebar-button-alone-normal txt-small',
        child: MaterialIcon('keyboard_arrow_leftenergy_savings_leaf', 'larger', {
            xalign: 0.2,
        }),
        onClicked: (button) => {
            const revealed = PowerSavers.revealChild;
            PowerSavers.revealChild = !revealed;
            button.toggleClassName('sidebar-button-active', !revealed);
            button.child.label = revealed ? 'keyboard_arrow_leftenergy_savings_leaf' : 'keyboard_arrow_rightenergy_savings_leaf';
        },
        setup: (button) => setupCursorHover(button),
    })
    return Widget.Box({
        className: 'sidebar-group spacing-h-10',
        children: [
            PowerSavers,
            Widget.Box({
                vertical: true,
                className: 'spacing-v-5',
                children: [
                    ModulePowerSavers,
                    Widget.Box({
                        className: 'spacing-h-5',
                        children: [
                            ModuleNightLight(),
                            ModuleRecord(),
                        ]
                    })
                ]
            })
        ]
    });
}
