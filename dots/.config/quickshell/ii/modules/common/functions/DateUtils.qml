pragma Singleton
import Quickshell

Singleton {
    id: root

    function getMonday(date, american = false) {
        const d = new Date(date); // Copy
        const day = d.getDay();   // 0 = Sunday, 1 = Monday, ..., 6 = Saturday

        // Calculate difference to Monday
        if (american) {
            // Week starts on Sunday
            d.setDate(d.getDate() - day);
        } else {
            // Week starts on Monday
            const diff = day === 0 ? -6 : 1 - day;
            d.setDate(d.getDate() + diff);
        }

        return d;
    }

    function sameDate(d1, d2) {
        return (
            d1.getFullYear() === d2.getFullYear() &&
            d1.getMonth() === d2.getMonth() &&
            d1.getDate() === d2.getDate()
        );
    }

    function getIthDayDateOfSameWeek(date, i, american = false) {
        const monday = root.getMonday(date, american);
        const targetDate = new Date(monday);
        targetDate.setDate(monday.getDate() + i);
        return targetDate;
    }
}
