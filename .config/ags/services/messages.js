const { Notify, GLib, Gio } = imports.gi;
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
import Battery from 'resource:///com/github/Aylur/ags/service/battery.js';

export function fileExists(filePath) {
    let file = Gio.File.new_for_path(filePath);
    return file.query_exists(null);
}

const FIRST_RUN_FILE = "firstrun.txt";
const FIRST_RUN_PATH = GLib.build_filenamev([GLib.get_user_cache_dir(), "ags", "user", FIRST_RUN_FILE]);
const FIRST_RUN_FILE_CONTENT = "Just a file to confirm that you have been greeted ;)";
const APP_NAME = "illogical-impulse";
const FIRST_RUN_NOTIF_TITLE = "Welcome!";
const FIRST_RUN_NOTIF_BODY = `Looks like this is your first run. For a list of keybinds, hit <span foreground="#c06af1" font_weight="bold">Super + /</span>.`;

export async function firstRunWelcome() {
    if (!fileExists(FIRST_RUN_PATH)) {
        Utils.writeFile(FIRST_RUN_FILE_CONTENT, FIRST_RUN_PATH)
            .then(() => {
                // Note that we add a little delay to make sure the cool circular progress works
                Utils.execAsync(['hyprctl', 'keyword', 'bind', "Super,Slash,exec,ags -t cheatsheet"]).catch(print);
                Utils.execAsync(['bash', '-c',
                    `sleep 0.5; notify-send "Millis since epoch" "$(date +%s%N | cut -b1-13)"; sleep 0.5; notify-send '${FIRST_RUN_NOTIF_TITLE}' '${FIRST_RUN_NOTIF_BODY}' -a '${APP_NAME}' &`
                ]).catch(print)
            })
            .catch(print);
    }
}

const BATTERY_WARN_LEVELS = [20, 15, 5];
const BATTERY_WARN_TITLES = ["Low battery", "Very low battery", 'Critical Battery']
const BATTERY_WARN_BODIES = ["Plug in the charger", "You there?", 'PLUG THE CHARGER ALREADY']
var batteryWarned = false;
async function batteryMessage() {
    const perc = Battery.percent;
    const charging = Battery.charging;
    if(charging) {
        batteryWarned = false;
        return;
    }
    for (let i = BATTERY_WARN_LEVELS.length - 1; i >= 0; i--) {
        if (perc <= BATTERY_WARN_LEVELS[i] && !charging && !batteryWarned) {
            batteryWarned = true;
            Utils.execAsync(['bash', '-c',
                `notify-send "${BATTERY_WARN_TITLES[i]}" "${BATTERY_WARN_BODIES[i]}" -u critical -a 'ags' &`
            ]).catch(print);
            break;
        }
    }
}

// Run them
firstRunWelcome();
Utils.timeout(1, () => {
    Battery.connect('changed', () => batteryMessage().catch(print));
})