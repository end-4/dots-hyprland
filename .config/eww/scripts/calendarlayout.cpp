#include <chrono>
#include <ctime>
#include <iostream>
#include <string>
using namespace std;

int year, month, day, weekday, weekdayOfMonthFirst;
bool leapYear;
int daysInMonth, daysInLastMonth, daysInNextMonth;
bool highlight = true;

int calendar[6][7];
int today[6][7];

void getTime() {
    // Time
    time_t now = time(0);
    tm* ltm = localtime(&now);
    // To vars
    year = 1900 + ltm->tm_year;
    month = 1 + ltm->tm_mon;
    day = ltm->tm_mday;
    weekday = ltm->tm_wday - 1;
    weekdayOfMonthFirst = (weekday + 35 - (day - 1)) % 7;
    // cout << weekday << ", " << day << '/' << month << '/' << year << '\n';
}

void setTime(int wd, int d, int m, int y) {
    wd--;
    highlight = false;
    year = y;
    month = m;
    day = d;
    weekday = wd;
    weekdayOfMonthFirst = (weekday + 35 - (day - 1)) % 7;
    // cout << weekday << ", " << day << '/' << month << '/' << year << '\n';
}

void checkLeapYear() {
    if (year % 400 == 0 || (year % 4 == 0 && year % 100 != 0))
        leapYear = true;
    else
        leapYear = false;
}

void getMonthDays() {
    // Days in this month
    if ((month <= 7 && month % 2 == 1) || (month >= 8 && month % 2 == 0))
        daysInMonth = 31;
    else if (month == 2 && leapYear)
        daysInMonth = 29;
    else if (month == 2 && !leapYear)
        daysInMonth = 28;
    else
        daysInMonth = 30;
    // Days in next month
    if (month == 1 && leapYear)
        daysInNextMonth = 29;
    else if (month == 1 && !leapYear)
        daysInNextMonth = 28;
    else if ((month <= 7 && month % 2 == 1) || (month >= 8 && month % 2 == 0))
        daysInNextMonth = 30;
    else
        daysInNextMonth = 31;
    // Days in last month
    if (month == 3 && leapYear)
        daysInLastMonth = 29;
    else if (month == 3 && !leapYear)
        daysInLastMonth = 28;
    else if ((month <= 7 && month % 2 == 1) || (month >= 8 && month % 2 == 0))
        daysInLastMonth = 30;
    else
        daysInLastMonth = 31;
}

void calcCalendar() {
    int monthDiff = (weekdayOfMonthFirst == 0 ? 0 : -1);
    int dim = daysInLastMonth;
    int i = 0, j = 0;
    int toFill = (weekdayOfMonthFirst == 0
                      ? 1
                      : (daysInLastMonth - (weekdayOfMonthFirst - 1)));

    while (i < 6 && j < 7) {
        // Fill it
        calendar[i][j] = toFill;
        if (toFill == day && monthDiff == 0 && highlight)
            today[i][j] = 1;
        else if (monthDiff == 0)
            today[i][j] = 0;
        else
            today[i][j] = -1;
        // Next day
        toFill++;
        if (toFill > dim) {
            monthDiff++;
            if (monthDiff == 0)
                dim = daysInMonth;
            else if (monthDiff == 1)
                dim = daysInNextMonth;
            toFill = 1;
        }
        // Next tile
        j++;
        if (j == 7) {
            j = 0;
            i++;
        }
    }
}

void printCalendar() {
    cout << '[';
    for (int i = 0; i < 6; i++) {
        cout << '[';
        for (int j = 0; j < 7; j++) {
            cout << "{\"day\":" << calendar[i][j]
                 << ",\"today\":" << today[i][j] << "}";
            if (j < 7 - 1) cout << ',';
        }
        cout << ']';
        if (i < 6 - 1) cout << ',';
    }
    cout << ']';
}

int main(int argc, char* argv[]) {
    if (argc == 1)
        getTime();
    else if(argc == 5)
        setTime(stoi(argv[1]), stoi(argv[2]), stoi(argv[3]), stoi(argv[4]));
    else 
        cout << " - Run \"calendarlayout\" to get calendar for today\n - Run\"calendarlayout <weekday> <day> <month> <year>\" to get calendar of the day specified";
    checkLeapYear();
    getMonthDays();
    calcCalendar();
    printCalendar();
}