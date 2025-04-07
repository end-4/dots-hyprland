const { Gio, GLib } = imports.gi;
import Service from 'resource:///com/github/Aylur/ags/service.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
import { darkMode } from '../modules/.miscutils/system.js';
const { exec, execAsync } = Utils;

const timeBefore = (time1, time2) => { // Arrays of [hour, minute]
    if (time1[0] == time2[0]) return time1[1] < time2[1];
    return time1[0] < time2[0];
}

const timeSame = (time1, time2) => // Arrays of [hour, minute]
    (time1[0] == time2[0] && time1[1] == time2[1]);

const timeBeforeOrSame = (time1, time2) => // Arrays of [hour, minute]
    (timeBefore(time1, time2) || timeSame(time1, time2));

const timeInRange = (time, rangeStart, rangeEnd) => { // Arrays of [hour, minute]
    if (timeBefore(rangeStart, rangeEnd))
        return (timeBeforeOrSame(rangeStart, time) && timeBeforeOrSame(time, rangeEnd))
    else { // rangeEnd < rangeStart, meaning it ends the following day
        rangeEnd[0] += 24;
        if (timeBefore(time, rangeStart)) time[0] += 24;
        return (timeBeforeOrSame(rangeStart, time) && timeBeforeOrSame(time, rangeEnd))
    }

}

export async function startAutoDarkModeService() {
    Utils.interval(userOptions.time.interval, () => {
        if ((!userOptions.appearance.autoDarkMode.enabled)) return;
        const fromTime = (userOptions.appearance.autoDarkMode.from).split(':').map(Number);
        const toTime = (userOptions.appearance.autoDarkMode.to).split(':').map(Number);
        if (fromTime == toTime) return;
        const currentDateTime = GLib.DateTime.new_now_local();
        const currentTime = [currentDateTime.get_hour(), currentDateTime.get_minute()];
        darkMode.value = timeInRange(currentTime, fromTime, toTime);
    })
}
