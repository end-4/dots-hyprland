#include <pwd.h>
#include <sys/stat.h>
#include <unistd.h>

#include <algorithm>
#include <cctype>
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
    string filename;
    string filepath;
    bool show;
};

string username;
vector<DesktopEntry> allApps;
json apps;
int mode = 0;  // 0: Object, 1: Array, 2: Start (Contains JSON for letters)
string iconTheme = "";

// Returns the file name from a path
std::string getFileName(const std::string& path) {
    // Find the last position of '/' or '\' in the path
    size_t pos = path.find_last_of("/\\");
    // If none is found, return the whole path
    if (pos == std::string::npos) return path;
    // Otherwise, return the substring after the last slash
    return path.substr(pos + 1);
}

// Returns the file name without extension from a path
string getFileNameNoExt(const string& path) {
    string filename = getFileName(path);  // Get file name (with extension)
    size_t pos = filename.find_last_of(".");
    if (pos == string::npos) return filename;  // Name found
    return filename.substr(0, pos);
}

// Function to check if file exists, if yes read it
string readIfExists(const string& name) {
    ifstream f(name.c_str());
    stringstream buffer;
    if (f) {                  // check if the file was opened successfully
        buffer << f.rdbuf();  // read the whole file into a string stream
        f.close();            // close the file when done
    }
    return buffer.str();  // return the string stream as a string
}

void writeToFile(const string& name, const string& content) {
    ofstream f(name.c_str(), ios::app);  // open the file in append mode
    if (f) {                   // check if the file was opened successfully
        f << content << "\n";  // write the content to the file
        f.close();             // close the file when done
    } else {
        cerr << "Error: could not open " << name
             << "\n";  // print an error message to the standard error
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

string getIconPath(string iconname) {
    if (iconTheme == "") {
        iconTheme =
            exec(string("gsettings get org.gnome.desktop.interface icon-theme")
                     .c_str());
        iconTheme.pop_back();
        // cout << "icon theme: " << iconTheme << '\n';
    }
    if (iconname.size() == 0) {
        return "";
    } else if (iconname[0] == '/') {
        return iconname;  // Already absolute path
    } else if (iconname[0] == '\n') {
        return "";  // wtf
    }
    string path = readIfExists("/home/" + username + "/.config/eww/scripts/cache/" + iconname);
    if (path == "") {
        path = exec(string("geticons -t " + iconTheme + " " + string(iconname) +
                           " | head -n 1")
                        .c_str());
        // cout << "path: " << path << '\n';
        writeToFile("/home/" + username + "/.config/eww/scripts/cache/" + iconname, path);
        // cout << "icon name: " << iconname << '\n';
        // cout << "path: " << path << '\n';
    }
    while (path.size() > 0 && *path.rbegin() == '\n')
        path.pop_back();  // Remove '\n'
    return path;
}

// A function that reads a .desktop file and returns a DesktopEntry struct
DesktopEntry readDesktopFile(const string& filename) {
    DesktopEntry entry;
    entry.show = true;
    entry.filename = getFileNameNoExt(filename);
    entry.filepath = filename;

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
                // Store properties
                if (key == "Name") {
                    entry.name = value;
                } else if (key == "Exec") {
                    entry.exec = value;
                } else if (key == "Icon") {
                    entry.icon = getIconPath(value);
                } else if (key == "NoDisplay" && value == "true") {
                    entry.show = false;
                }
            }
        }
        file.close();
    }
    return entry;
}

string lowercaseOf(string s) {
    for (char& c : s) {
        c = tolower(c);
    }
    return s;
}

bool lf(DesktopEntry a, DesktopEntry b) {
    if (tolower(a.name[0]) == tolower(b.name[0]))
        return a.name < b.name;
    else
        return tolower(a.name[0]) < tolower(b.name[0]);
}

// A function that prints out all desktop entry names and exec properties in a
// given directory
void getDesktopEntries(const string& dirname) {
    // Iterate over all files in the directory
    for (const auto& entry : filesystem::directory_iterator(dirname)) {
        // Check if the file has a .desktop extension
        if (entry.path().extension() == ".desktop") {
            // Read the file and print its name and exec properties
            DesktopEntry thisEntry = readDesktopFile(entry.path());
            // cout << thisEntry.name << " [icon: " << thisEntry.icon << "]\n";
            if (thisEntry.show) allApps.push_back(thisEntry);
        }
    }
}

void toJson() {
    sort(allApps.begin(), allApps.end(), lf);
    int i = -1;
    for (const auto& entry : allApps) {
        i++;
        // cout << entry.name << ", ";
        json thisApp;
        thisApp["name"] = entry.name;
        thisApp["icon"] = entry.icon;
        thisApp["exec"] = entry.exec;
        if (mode != 2) {
            thisApp["filename"] = entry.filename;
            thisApp["filepath"] = entry.filepath;
        }
        // Get
        if (mode == 0)
            apps[entry.name] = thisApp;
        else if (mode == 1)
            apps.push_back(thisApp);
        else if (mode == 2) {
            apps.push_back(thisApp);
        }
    }
    cout << apps << '\n';
}

string getUsername() {
    uid_t uid = geteuid();
    struct passwd* pw = getpwuid(uid);
    return pw->pw_name;
}

void addLetters() {
    for (char c = 'A'; c <= 'Z'; c++) {
        DesktopEntry thisLetter;
        thisLetter.name = c;
        thisLetter.exec = "";
        thisLetter.icon = "_letter";
        allApps.push_back(thisLetter);
    }
}

int main(int argc, char* argv[]) {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    if (argc == 3 && string(argv[1]) == "--mode") {
        if (string(argv[2]) == "object")
            mode = 0;
        else if (string(argv[2]) == "array")
            mode = 1;
        else if (string(argv[2]) == "start")
            mode = 2;
        else
            mode = stoi(string(argv[2]));
    }

    username = getUsername();
    // Print all desktop entries in common locations
    string entryDirs[3] = {"/usr/share/applications/",
                           "/home/" + username + "/.local/share/applications",
                           "/var/lib/flatpak/exports/share/applications"};
    for (string directory : entryDirs) {
        if (filesystem::exists(directory))
            getDesktopEntries(directory);
    }
    if (mode == 2) addLetters();
    // Get a json and print
    toJson();
}