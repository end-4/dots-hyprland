#include <unistd.h>

#include <array>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

#include "nlohmann/json.hpp"

#define SLEEP_SECONDS 5

using namespace std;
using json = nlohmann::json;

string fileContents, currentLang;
json languages;

string readIfExists(const string& name) {
    ifstream f(name.c_str());
    stringstream buffer;
    if (f) {                  // check if the file was opened successfully
        buffer << f.rdbuf();  // read the whole file into a string stream
        f.close();            // close the file when done
    }
    return buffer.str();  // return the string stream as a string
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

void switchLang(const json& langJson) {
    string cmd;
    cmd = "ibus engine " + string(langJson["name_ibus"]);
    exec(&cmd[0]);
    cmd = "eww update lang_ibus='" + string(langJson.dump()) + "'";
    exec(&cmd[0]);
}

void cycleLang() {
    for (int i = 0; i < languages.size(); i++) {
        json lang = languages[i];
        if (string(lang["name_ibus"]) == currentLang) {
            json toSwitchTo = languages[(i + 1) % int(languages.size())];
            switchLang(toSwitchTo);
        }
    }
}

void getCurrentLang() {
    for (json lang : languages) {
        if (string(lang["name_ibus"]) == currentLang) {
            cout << lang << '\n';
            break;
        }
    }
}

int main(int argc, char* argv[]) {
    // Change workdir
    string workdir = string(getenv("HOME")) + "/.config/eww";
    chdir(&workdir[0]);
    // Get lang list, current lang
    fileContents = readIfExists("modules/langs.json");
    languages = json::parse(fileContents);
    currentLang = exec("ibus engine");
    currentLang.pop_back();  // Remove trailing newline
    // Cycle?
    if (argc > 1 && string(argv[1]) == "--cycle") {
        cycleLang();
        return 0;
    }
    if (argc > 2 && string(argv[1]) == "--switch") {
        switchLang(json::parse(string(argv[2])));
        return 0;
    }

    cout << "{\"name\":\"English (United "
            "States)\",\"name_abbr\":\"ENG\",\"name_ibus\":\"xkb:us::eng\"}\n";
    while (true) {
        getCurrentLang();
        sleep(5);
    }
}