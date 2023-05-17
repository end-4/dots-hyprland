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
    searchTerm = searchTerm.substr(6);
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
    cout << ']';
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
    cout << ']';
    exit(0);
}

void tryCalculate() {
    string calcCommand =
        "rink '" + searchTerm + "' | tail -1 | sed 's/approx. //g'";
    string results = exec(&calcCommand[0]);
    results = results.substr(0, results.find_last_of("(") - 1);
    // cout << results << '\n';
    cout
        << "[{\"name\":\"" << results
        << "\",\"icon\":\"images/svg/dark/calculator.svg\",\"exec\":\"wl-copy '"
        << results << "'\"}]";
    exit(0);
}

int main(int argc, char* argv[]) {
    // ios::sync_with_stdio(false);
    // cin.tie(nullptr);
    if (argc == 1) {
        cout << "[{\"name\": \"Type something!\"}]";
        return 0;
    }
    searchTerm = argv[1];
    if (searchTerm == "--calculator") calcPrompt();
    if (searchTerm.find(">load") != string::npos) tryThemeCmd();
    // Get app names and entries
    getAppNames();
    getAppJson();
    // Attempt searches in order. Each search will exit if success
    tryAppSearch();
    tryCalculate();

    cout << results;
}