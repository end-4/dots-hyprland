import { GLib, interval } from 'astal';
import { userOptions } from '../modules/core/configuration/user_options';
import { darkMode } from '../modules/core/miscutils/system';

const timeBefore = (time1: number[], time2: number[]) => {
    // Arrays of [hour, minute]
    if (time1[0] == time2[0]) return time1[1] < time2[1];
    return time1[0] < time2[0];
};

const timeSame = (
    time1: number[],
    time2: number[] // Arrays of [hour, minute]
) => time1[0] == time2[0] && time1[1] == time2[1];

const timeBeforeOrSame = (
    time1: number[],
    time2: number[] // Arrays of [hour, minute]
) => timeBefore(time1, time2) || timeSame(time1, time2);

const timeInRange = (time: number[], rangeStart: number[], rangeEnd: number[]) => {
    // Arrays of [hour, minute]
    if (timeBefore(rangeStart, rangeEnd)) return timeBeforeOrSame(rangeStart, time) && timeBeforeOrSame(time, rangeEnd);
    else {
        // rangeEnd < rangeStart, meaning it ends the following day
        rangeEnd[0] += 24;
        if (timeBefore(time, rangeStart)) time[0] += 24;
        return timeBeforeOrSame(rangeStart, time) && timeBeforeOrSame(time, rangeEnd);
    }
};

export async function startAutoDarkModeService() {
    interval(userOptions.time.interval, () => {
        if (!userOptions.appearance.autoDarkMode.enabled) return;
        const fromTime = userOptions.appearance.autoDarkMode.from.split(':').map(Number);
        const toTime = userOptions.appearance.autoDarkMode.to.split(':').map(Number);
        if (fromTime == toTime) return;
        const currentDateTime = GLib.DateTime.new_now_local();
        const currentTime = [currentDateTime.get_hour(), currentDateTime.get_minute()];
        darkMode.set(timeInRange(currentTime, fromTime, toTime));
    });
}
