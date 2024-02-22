#include <array>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

#include "nlohmann/json.hpp"
using namespace std;
using json = nlohmann::json;

string searchTerm;
string results;
vector<string> entryNames;
json appEntries;

bool updateInfo = false;

void splitString(const std::string& str, const char delimiter,
                 std::vector<std::string>& result) {
    std::string line;
    std::istringstream stream(str);
    while (std::getline(stream, line)) {
        if (!line.empty()) {
            if (line.back() == delimiter) {
                line.pop_back();
            }
            result.push_back(line);
        }
    }
}

string exec(const char* cmd) {
    array<char, 128> buffer;
    string result;
    unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
    if (!pipe) {
        throw runtime_error("popen() failed!");
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    return result;
}

bool likelyNotMath(const string& expression) {
    char firstChar = expression[0];
    if (firstChar >= '0' && firstChar <= '9') return false;
    return true;
}

void calcPrompt() {
    cout << "[{\"name\":\"Calculator - Type "
            "something!\",\"icon\":\"images/svg/dark/"
            "calculator.svg\",\"exec\":\"wl-copy \\\"Clipboard contents "
            ";)\\\"\"}]";
    exec(
        "eww update winsearch_actions='{\"name\":\"Calculator - Type "
        "something!\",\"icon\":\"images/svg/dark/"
        "calculator.svg\",\"exec\":\"wl-copy \\\"Clipboard contents "
        ";)\\\"\"}' &");
    exec("eww update winsearch_actions_type='Math result' &");
    exit(0);
}

void getAppNames() {
    string searchCommand =
        "cat 'scripts/cache/entrynames.txt' | fzf --filter=\"" + searchTerm +
        "\" | head -n 10";
    string results = exec(&searchCommand[0]);
    splitString(results, '\n', entryNames);
}

void getAppJson() {
    ifstream file("scripts/cache/entries.txt");
    file >> appEntries;
}

void tryThemeCmd() {
    if (searchTerm.size() >= 6)
        searchTerm = searchTerm.substr(6);
    else
        searchTerm = " ";
    string searchCommand =
        "ls css/savedcolors/ | grep .txt | sed 's/_iconcolor_//g' | sed "
        "'s/.txt//g' | fzf --filter='" +
        searchTerm + "'";
    string results = exec(&searchCommand[0]);
    splitString(results, '\n', entryNames);
    cout << '[';
    for (int i = 0; i < entryNames.size(); i++) {
        string entryName = entryNames[i];
        cout << '{';
        cout << "\"name\":\"" << entryName << "\",\"exec\":\">load "
             << entryName << "\"";
        cout << '}';
        if (i < entryNames.size() - 1) cout << ',';
    }
    cout << ']' << endl;
    if (updateInfo) {
        string entryName = entryNames[0];
        string updateCmd = "eww update winsearch_actions='{\"name\":\"" +
                           entryName + "\",\"exec\":\">load " + entryName +
                           "\"}'";
        exec(&updateCmd[0]);
        exec("eww update winsearch_actions_type='Color theme'");
    }
    exit(0);
}

void tryAppSearch() {
    if (entryNames.size() == 0) return;  // No app found, skip it
    cout << '[';
    for (int i = 0; i < entryNames.size(); i++) {
        string entryName = entryNames[i];
        cout << appEntries[entryName];
        if (i < entryNames.size() - 1) cout << ',';
    }
    cout << ']' << endl;
    if (updateInfo) {
        string updateCmd = "eww update winsearch_actions='" +
                           string(appEntries[entryNames[0]].dump()) + "'";
        exec(&updateCmd[0]);
        exec("eww update winsearch_actions_type='Application'");
    }
    exit(0);
}

void tryCalculate() {
    if (likelyNotMath(searchTerm)) return;
    string calcCommand = "qalc '" + searchTerm + "'";
    string results = exec(&calcCommand[0]);
    results = results.substr(results.find_first_of("=") + 2);
    if(results.back() == '\n') results.pop_back();
    // cout << results << '\n';
    cout
        << "[{\"name\":\"" << results
        << "\",\"icon\":\"images/svg/dark/calculator.svg\",\"exec\":\"wl-copy '"
        << results << "'\"}]" << endl;
    if (updateInfo) {
        string updateCmd =
            "eww update "
            "winsearch_actions='{\"name\":\"'\"" +
            results +
            "\"'\",\"icon\":\"images/svg/dark/"
            "calculator.svg\",\"exec\":\"wl-copy '" +
            results + "'\"}'";
        exec(&updateCmd[0]);
        exec("eww update winsearch_actions_type='Math result'");
    }
    exit(0);
}

void commandOnly() {
    cout << "[]" << endl;
    if (updateInfo) {
        string updateCmd =
            "eww update "
            "winsearch_actions='{\"name\":\"'\"" +
            searchTerm +
            "\"'\",\"icon\":\"images/svg/dark/"
            "protocol.svg\",\"exec\":\"" +
            searchTerm + "\"}'";
        exec(&updateCmd[0]);
        exec("eww update winsearch_actions_type='Run command'");
    }
    exit(0);
}

int main(int argc, char* argv[]) {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    // Arguments
    if (argc == 1) {
        cout << "[{\"name\": \"Type something!\"}]";
        return 0;
    }
    if (argc > 2 && string(argv[2]) == "--updateinfo") updateInfo = true;
    searchTerm = argv[1];

    // Special commands
    if (searchTerm == "--calculator") calcPrompt();
    if (searchTerm[0] == '>') {
        if (searchTerm.find(">load") != string::npos)
            tryThemeCmd();
        else {
            cout << "[]" << endl;
            exit(0);
        }
    }
    // Get app names and entries
    getAppNames();
    getAppJson();
    // Attempt searches in order. Each search will exit if success
    tryCalculate();
    tryAppSearch();
    commandOnly();

    cout << results;
}