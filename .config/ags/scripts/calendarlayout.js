export function getCalendarLayout(d, highlight) {
    if (!d) d = new Date();
    var calendar = [...Array(6)].map(() => Array(7));
    var today = [...Array(6)].map(() => Array(7));
    const year = d.getFullYear();
    const month = d.getMonth() + 1;
    const day = d.getDate();
    const weekdayOfMonthFirst = new Date(`${year}-${month}-01`).getDay();
    const leapYear = (year % 400 == 0 || (year % 4 == 0 && year % 100 != 0));
    const daysInMonth = (((month <= 7 && month % 2 == 1) || (month >= 8 && month % 2 == 0)) ? 31 : ((month == 2 && leapYear) ? 29 : ((month == 2 && !leapYear) ? 28 : 30)));
    const daysInNextMonth = ((month == 1 && leapYear) ? 29 : ((month == 1 && !leapYear) ? 28 : ((month == 7 || month == 12) ? 31 : (((month <= 6 && month % 2 == 1) || (month >= 8 && month % 2 == 0)) ? 30 : 31))));
    const daysInLastMonth = ((month == 3 && leapYear) ? 29 : ((month == 3 && !leapYear) ? 28 : ((month == 1 || month == 8) ? 31 : ((month <= 7 && month % 2 == 1) || (month >= 9 && month % 2 == 0)) ? 30 : 31)));
    var monthDiff = (weekdayOfMonthFirst == 0 ? 0 : -1);
    var dim = daysInLastMonth;
    var toFill = (weekdayOfMonthFirst == 0 ? 1 : (daysInLastMonth + 1 - weekdayOfMonthFirst));
    var i = 0, j = 0;
    while (i < 6 && j < 7) {
        calendar[i][j] = toFill;
        if (toFill == day && monthDiff == 0 && highlight) today[i][j] = 1;
        else if (monthDiff == 0) today[i][j] = 0;
        else today[i][j] = -1;
        toFill++;
        if (toFill > dim) {
            monthDiff++;
            if (monthDiff == 0) dim = daysInMonth;
            else if (monthDiff == 1) dim = daysInNextMonth;
            toFill = 1;
        }
        j++;
        if (j == 7) {
            j = 0;
            i++;
        }
    }
    var cal = [];
    for (var i = 0; i < 6; i++) {
        var arr = [];
        for (var j = 0; j < 7; j++) {
            arr.push({
                day: calendar[i][j],
                today: today[i][j]
            });
        }
        cal.push(arr);
    }

    return cal;
}

export default getCalendarLayout;

// export function getCalendarLayout(d, highlight) {
//     if (!d) d = new Date();
//     var calendar = [...Array(6)].map(() => Array(7));
//     var today = [...Array(6)].map(() => Array(7));
//     const year = d.getFullYear();
//     const month = d.getMonth() + 1;
//     const day = d.getDate();
//     const weekdayOfMonthFirst = new Date(`${year}-${month}-01`).getDay();
//     const leapYear = (year % 400 == 0 || (year % 4 == 0 && year % 100 != 0));
//     const daysInMonth = (((month <= 7 && month % 2 == 1) || (month >= 8 && month % 2 == 0)) ? 31 : ((month == 2 && leapYear) ? 29 : ((month == 2 && !leapYear) ? 28 : 30)));
//     const daysInNextMonth = ((month == 1 && leapYear) ? 29 : ((month == 1 && !leapYear) ? 28 : ((month == 7 || month == 12) ? 31 : (((month <= 6 && month % 2 == 1) || (month >= 8 && month % 2 == 0)) ? 30 : 31))));
//     const daysInLastMonth = ((month == 3 && leapYear) ? 29 : ((month == 3 && !leapYear) ? 28 : ((month == 1 || month == 8) ? 31 : ((month <= 7 && month % 2 == 1) || (month >= 9 && month % 2 == 0)) ? 30 : 31)));
//     var monthDiff = (weekdayOfMonthFirst == 1 ? 0 : -1);
//     var dim = daysInLastMonth;
//     var toFill = (weekdayOfMonthFirst == 1 ? 1 : (weekdayOfMonthFirst == 0 ? (daysInLastMonth - 5) : (daysInLastMonth + 2 - weekdayOfMonthFirst)));
//     var i = 0, j = 0;
//     while (i < 6 && j < 7) {
//         calendar[i][j] = toFill;
//         if (toFill == day && monthDiff == 0 && highlight) today[i][j] = 1;
//         else if (monthDiff == 0) today[i][j] = 0;
//         else today[i][j] = -1;
//         toFill++;
//         if (toFill > dim) {
//             monthDiff++;
//             if (monthDiff == 0) dim = daysInMonth;
//             else if (monthDiff == 1) dim = daysInNextMonth;
//             toFill = 1;
//         }
//         j++;
//         if (j == 7) {
//             j = 0;
//             i++;
//         }
//     }
//     var cal = [];
//     for (var i = 0; i < 6; i++) {
//         var arr = [];
//         for (var j = 0; j < 7; j++) {
//             arr.push({
//                 day: calendar[i][j],
//                 today: today[i][j]
//             });
//         }
//         cal.push(arr);
//     }

//     return cal;
// }

// export default getCalendarLayout;