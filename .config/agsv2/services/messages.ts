import { Gio, GLib, execAsync, timeout, writeFileAsync } from "astal";
import AstalBattery from "gi://AstalBattery";
import { userOptions } from "../modules/core/configuration/user_options";


export function fileExists(filePath: string) {
    const file = Gio.File.new_for_path(filePath);
    return file.query_exists(null);
}

const BATTERY = AstalBattery.get_default();
const FIRST_RUN_FILE = "firstrun.txt";
const FIRST_RUN_PATH = `${GLib.get_user_state_dir()}/agsv2/user/${FIRST_RUN_FILE}`;
const FIRST_RUN_FILE_CONTENT = "Just a file to confirm that you have been greeted ;)";
const APP_NAME = "illogical-impulse";
const FIRST_RUN_NOTIF_TITLE = "Welcome!";
const FIRST_RUN_NOTIF_BODY = `First run? 👀 <span foreground="#FF0202" font_weight="bold">CTRL+SUPER+T</span> to pick a wallpaper (or styles will break!)\nFor a list of keybinds, hit <span foreground="#c06af1" font_weight="bold">Super + /</span>.`;

let batteryWarned = false;
async function batteryMessage() {
    const isBattery = BATTERY.isBattery;
    if (!isBattery) {
        return;
    }
    const perc = BATTERY.percentage;
    const charging = BATTERY.charging;
    if (charging) {
        batteryWarned = false;
        return;
    }
    for (let i = userOptions.battery.warnLevels.length - 1; i >= 0; i--) {
        if (perc <= userOptions.battery.warnLevels[i] && !charging && !batteryWarned) {
            batteryWarned = true;
            execAsync(['bash', '-c',
                `notify-send "${userOptions.battery.warnTitles[i]}" "${userOptions.battery.warnMessages[i]}" -u critical -a '${APP_NAME}' -t 69420 &`
            ]).catch(print);
            break;
        }
    }
    if (perc <= userOptions.battery.suspendThreshold) {
        execAsync(['bash', '-c',
            `notify-send "Suspending system" "Critical battery level (${perc}% remaining)" -u critical -a '${APP_NAME}' -t 69420 &`
        ]).catch(print);
        execAsync('systemctl suspend').catch(print);
    }
}

export async function startBatteryWarningService() {
    timeout(1, () => {
        batteryMessage().catch(print);
    });
}

export async function firstRunWelcome() {
    GLib.mkdir_with_parents(`${GLib.get_user_state_dir()}/agsv2/user`, 755);
    if (!fileExists(FIRST_RUN_PATH)) {
        execAsync([`bash`, `-c`, `${GLib.get_user_config_dir()}/agsv2/scripts/color_generation/switchwall.sh '${GLib.get_user_config_dir()}/agsv2/assets/images/default_wallpaper.png'`]).catch(print);
        writeFileAsync(FIRST_RUN_PATH, FIRST_RUN_FILE_CONTENT)
            .then(() => {
                // Note that we add a little delay to make sure the cool circular progress works
                execAsync(['hyprctl', 'keyword', 'bind', 'Super,Slash,exec,for ((i=0; i<$(hyprctl monitors -j | jq length); i++)); do ags -t "cheatsheet""$i"; done']).catch(print);
                execAsync(['bash', '-c',
                    `sleep 0.5; notify-send "Millis since epoch" "$(date +%s%N | cut -b1-13)"; sleep 0.5; notify-send '${FIRST_RUN_NOTIF_TITLE}' '${FIRST_RUN_NOTIF_BODY}' -a '${APP_NAME}' &`
                ]).catch(print)
            })
            .catch(print);
    }
}
