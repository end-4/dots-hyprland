#include <pwd.h>
#include <unistd.h>

#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include "nlohmann/json.hpp"
using namespace std;
using json = nlohmann::json;

// A simple struct to store the name and exec properties of a desktop entry
struct DesktopEntry {
    string name;
    string exec;
    string icon;
    bool show;
};

string username;
vector<DesktopEntry> allApps;
json apps;
int mode = 0;  // 0: Object, 1: Array

// A function that reads a .desktop file and returns a DesktopEntry struct
DesktopEntry read_desktop_file(const string& filename) {
    DesktopEntry entry;
    entry.show = true;

    ifstream file(filename);
    if (file.is_open()) {
        string line;
        while (getline(file, line)) {
            // Skip comments and empty lines
            if (line.empty() || line[0] == '#') {
                continue;
            }
            if (line.substr(0, 1) == "[" &&
                line.substr(0, 15) == "[Desktop Action")
                break;
            // Split the line by '=' and store the key-value pair
            size_t pos = line.find('=');
            if (pos != string::npos) {
                string key = line.substr(0, pos);
                string value = line.substr(pos + 1);
                // Store the name and exec properties
                if (key == "Name") {
                    entry.name = value;
                } else if (key == "Exec") {
                    entry.exec = value;
                } else if (key == "Icon") {
                    entry.icon = value;
                } else if (key == "NoDisplay" && value == "true") {
                    entry.show = false;
                }
            }
        }
        // cout << entry.name << " " << entry.exec << " " << entry.icon << "\n";
        file.close();
    }
    return entry;
}

bool lf(DesktopEntry a, DesktopEntry b) { return a.name < b.name; }

// A function that prints out all desktop entry names and exec properties in a
// given directory
void get_desktop_entries(const string& dirname) {
    // Check if the directory exists
    if (!filesystem::exists(dirname) || !filesystem::is_directory(dirname)) {
        return;
    }
    // Iterate over all files in the directory
    for (const auto& entry : filesystem::directory_iterator(dirname)) {
        // Check if the file has a .desktop extension
        if (entry.path().extension() == ".desktop") {
            DesktopEntry thisEntry = read_desktop_file(entry.path());
            if (thisEntry.show) allApps.push_back(thisEntry);
        }
    }
}

void to_json() {
    sort(allApps.begin(), allApps.end(), lf);
    for (const auto& entry : allApps) {
        json thisApp;
        thisApp["name"] = entry.name;
        thisApp["icon"] = entry.icon;
        thisApp["exec"] = entry.exec;
        // Get
        if (mode == 0)
            apps[entry.name] = thisApp;
        else
            apps.push_back(thisApp);
    }
}

string get_username() {
    uid_t uid = geteuid();
    struct passwd* pw = getpwuid(uid);
    return pw->pw_name;
}

int main(int argc, char* argv[]) {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    if (argc == 3 && string(argv[1]) == "--mode") {
        if (string(argv[2]) == "object")
            mode = 0;
        else if (string(argv[2]) == "array")
            mode = 1;
        else
            mode = stoi(string(argv[2]));
    }

    username = get_username();
    // Print all desktop entries in /usr/share/applications/
    string entryDirs[3] = {"/usr/share/applications/",
                           "/home/" + username + "/.local/share/applications",
                           "/var/lib/flatpak/exports/share/applications"};
    for (string directory : entryDirs) {
        if (filesystem::exists(directory))
            get_desktop_entries(directory);
    }

    // Get em in the json object
    to_json();
    // Print
    for (const auto& entry : allApps) {
        cout << entry.name << '\n';
    }

    return 0;
}